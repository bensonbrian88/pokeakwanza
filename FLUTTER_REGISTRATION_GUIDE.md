# Flutter Registration Flow Implementation Guide

## Overview

This guide explains the complete registration flow with error handling, timeout management, and OTP verification.

## 1. Architecture

The registration system uses three layers:

1. **ApiService** - Low-level HTTP communication with Dio
2. **AuthService** - Business logic for authentication operations
3. **AuthProvider** - State management using ChangeNotifier

## 2. Configuration

### API Configuration (`lib/core/api/api_config.dart`)

```dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://127.0.0.1:8000/api';
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000/api'; // Android emulator special IP
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    return 'http://127.0.0.1:8000/api'; // iOS simulator
  } else {
    return 'http://127.0.0.1:8000/api'; // Default
  }
}

static const Duration connectTimeout = Duration(seconds: 30);
static const Duration receiveTimeout = Duration(seconds: 30);
```

**Key Points:**
- Android emulator uses `10.0.2.2` instead of `localhost` to reach the host machine
- Timeout increased from 10s to 30s
- Configurable per platform

## 3. Error Handling Flow

### Error Types Handled

1. **Timeout Errors**
   ```
   DioExceptionType.connectionTimeout
   DioExceptionType.receiveTimeout
   DioExceptionType.sendTimeout
   
   Message: "Server not responding. Please check your internet connection and try again."
   ```

2. **Network Errors (No Internet)**
   ```
   SocketException
   
   Message: "No internet connection. Please check your network and try again."
   ```

3. **Server Errors (500+)**
   ```
   Status: 500, 502, 503, etc.
   
   Message: Extracted from response if available, else "Server error. Please try again later."
   ```

4. **Validation Errors (422)**
   ```
   Status: 422
   Fields: errors.field_name[0]
   
   Message: "Field validation failed"
   ```

5. **Unauthorized (401)**
   ```
   Status: 401
   
   Message: "Invalid credentials. Please try again."
   ```

6. **Forbidden (403)**
   ```
   Status: 403
   
   Message: "Account not verified or access denied."
   ```

## 4. Debug Logging

All requests and responses are logged with emoji indicators:

```
📤 API POST: /api/register
   URL: http://10.0.2.2:8000/api/register
   Body: {name: John, email: john@example.com, ...}

✅ API Response (/api/register): 201
   Data: {message: Registration successful, user_id: 1, ...}

❌ API Error (/api/register): connectionTimeout
   Status: null
   Error: Connection timeout
```

Enable/disable debugging in `api_config.dart`:

```dart
static const bool enableDebugLogs = true; // Set to false in production
```

## 5. Registration Flow

### Step 1: User Input

```dart
final payload = {
  'name': nameController.text.trim(),
  'email': emailController.text.trim(),
  'phone': phoneController.text, // Gets normalized in API
  'password': passwordController.text,
  'password_confirmation': passwordController.text,
};
```

### Step 2: API Call

```dart
try {
  final result = await authProvider.register(payload);
  
  // Check if OTP verification required
  if (result['next'] == 'otp_verification') {
    final userId = result['user_id'];
    // Navigate to OTP screen
    Navigator.pushNamed(context, '/otp', arguments: userId);
  } else {
    // User logged in directly
    // Navigate to home
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }
} on Exception catch (e) {
  // Show error to user
  _showErrorDialog(context, e.toString());
}
```

### Step 3: Error Handling

In UI layer (Register Screen):

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(errorMessage),
    backgroundColor: Colors.red,
    duration: const Duration(seconds: 4),
  ),
);
```

### Step 4: OTP Verification

After receiving OTP from email:

```dart
final otpResult = await authProvider.verifyOtp(userId, otpCode);

if (otpResult['access_token'] != null) {
  // User verified, logged in, and token saved
  Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
}
```

## 6. HTTP Headers

All requests include:

```dart
'Accept': 'application/json'
'Content-Type': 'application/json'
'Authorization': 'Bearer <token>' (for authenticated requests)
```

## 7. Request/Response Examples

### Registration Request

```json
POST /api/register HTTP/1.1
Host: 10.0.2.2:8000
Content-Type: application/json
Accept: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "255700000000",
  "password": "SecurePass123",
  "password_confirmation": "SecurePass123"
}
```

### Registration Success Response (201)

```json
{
  "message": "Registration successful. OTP has been sent to your email.",
  "success": true,
  "next": "otp_verification",
  "user_id": 123,
  "user": {
    "id": 123,
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "255700000000"
  }
}
```

### Validation Error Response (422)

```json
{
  "message": "Validation failed",
  "errors": {
    "email": ["The email has already been taken."],
    "phone": ["The phone has already been taken."]
  }
}
```

### OTP Verification Request

```json
POST /api/verify-otp HTTP/1.1
Host: 10.0.2.2:8000
Content-Type: application/json

{
  "user_id": 123,
  "otp_code": "654321"
}
```

### OTP Verification Success Response (200)

```json
{
  "message": "Email verified successfully",
  "success": true,
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "user": {
    "id": 123,
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "255700000000",
    "is_verified": true
  }
}
```

## 8. Sample Register Screen

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stynext/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    try {
      final result = await authProvider.register({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text,
        'password': _passwordController.text,
        'password_confirmation': _confirmController.text,
      });

      if (result['next'] == 'otp_verification') {
        final userId = result['user_id'];
        Navigator.pushNamed(
          context,
          '/otp',
          arguments: {'user_id': userId, 'email': _emailController.text},
        );
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String message) {
    // Remove "Exception: " prefix if present
    String errorMessage = message
        .replaceAll('Exception: ', '')
        .replaceAll('FormatException: ', '');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Account')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (v) =>
                    v?.isEmpty == true ? 'Name is required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v?.isEmpty == true ? 'Email is required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v?.isEmpty == true ? 'Phone is required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => v == null || v.length < 8
                    ? 'Password must be at least 8 characters'
                    : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                decoration: InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (v) => v != _passwordController.text
                    ? 'Passwords do not match'
                    : null,
              ),
              SizedBox(height: 24),
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleRegister,
                    child: authProvider.isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(),
                          )
                        : Text('Register'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 9. Common Issues and Solutions

### Issue: "The request connection took longer than 0:00:10.000000"

**Solution:** Timeout increased to 30 seconds in ApiConfig. If still timing out:

1. Check backend is running: `php artisan serve`
2. Check Android emulator can reach backend: `adb shell ping 10.0.2.2`
3. Check firewall allows port 8000

### Issue: "No internet connection"

**Cause:** Device/emulator cannot reach backend

**Solutions:**
- Make sure emulator is connected: `adb devices`
- Test endpoint directly in browser: `http://10.0.2.2:8000/api/register`
- Check Laravel app is serving

### Issue: CORS error

**Solution:** Update `config/cors.php` in Laravel to allow all origins:

```php
'allowed_origins' => ['*'],
'allowed_headers' => ['*'],
'allowed_methods' => ['*'],
```

### Issue: OTP not being received

**Causes:**
- Email not configured in `.env`
- Queue worker not running: `php artisan queue:work`
- Mail driver set to `log` instead of `smtp`

**Solution:**
```bash
php artisan queue:work
# or for sync testing
QUEUE_CONNECTION=sync php artisan serve
```

## 10. Testing Checklist

- [ ] Update `ApiConfig.baseUrl` for your backend IP
- [ ] Ensure Laravel migrations are run: `php artisan migrate`
- [ ] Set up mail configuration in `.env`
- [ ] Start queue worker: `php artisan queue:work`
- [ ] Test registration with valid data
- [ ] Test validation errors (duplicate email, weak password)
- [ ] Test timeout (stop backend, wait 30+ seconds)
- [ ] Test OTP verification
- [ ] Test OTP expiration (wait 10 minutes)
- [ ] Verify user is marked as verified in database
- [ ] Verify token is stored locally via shared_preferences
- [ ] Test logout clears token

## 11. Production Deployment

1. **Disable debug logs:**
   ```dart
   static const bool enableDebugLogs = false;
   ```

2. **Update backend URL:**
   ```dart
   static String get baseUrl => 'https://api.youromain.com/api';
   ```

3. **Increase OTP timeout** (optional):
   ```php
   $this->otp_expires_at = now()->addMinutes(15); // 15 minutes
   ```

4. **Enable proper CORS:**
   ```php
   'allowed_origins' => [
       'https://yourapp.com',
       'https://app.yourapp.com',
   ],
   ```

5. **Use environment variables** for backend URL instead of hardcoding

6. **Enable queue processing** on production server

7. **Set up proper logging** and monitoring

## 12. Quick Start

To get started with the improved registration:

1. Update `lib/core/api/api_config.dart` with your backend URL
2. Run backend: `php artisan serve`
3. Ensure phone codes endpoint returns data for phone code selector
4. Create registration screen UI
5. Use `authProvider.register()` for registration
6. Handle success/error appropriately
7. Implement OTP verification screen
8. Test the complete flow
