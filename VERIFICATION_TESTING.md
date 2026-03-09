# Verification & Testing Guide

## Pre-Implementation Checklist

Before testing the registration flow, ensure:

- [ ] Flutter SDK is installed and up to date
- [ ] Android emulator is available and can connect to host
- [ ] Laravel backend is available
- [ ] Database with users table is created
- [ ] All 4 code files are updated (see CODE_CHANGES.md)

## Step 1: Verify Code Changes

### Verify ApiConfig
```bash
cd d:\E\ comence\ App\stynext
grep "static String get baseUrl" lib/core/api/api_config.dart
```
Expected: Should show dynamic baseUrl getter with Android emulator support

### Verify ApiService
```bash
grep "import 'dart:io'" lib/core/api/api_service.dart
```
Expected: Should import dart:io for SocketException

### Verify Timeout
```bash
grep "Duration(seconds: 30)" lib/core/api/api_service.dart
```
Expected: Should show 30-second timeout in BaseOptions

### Verify AuthProvider
```bash
grep "if (e.error is SocketException)" lib/providers/auth_provider.dart
```
Expected: Should show no internet error handling

## Step 2: Backend Verification

### Start Laravel Server
```bash
cd /path/to/laravel/app
php artisan serve
```
Expected: Server running on http://localhost:8000

### Verify Routes
```bash
php artisan route:list | grep api/register
```
Expected:
```
POST  api/register
POST  api/verify-otp
POST  api/resend-otp
```

### Verify Database
```bash
php artisan tinker
>>> Schema::getColumnListing('users');
```
Expected: Should include `otp_code`, `otp_expires_at`, `is_verified`

### Verify CORS
Check `config/cors.php`:
```php
'allowed_origins' => ['*'],
'allowed_headers' => ['*'],
'allowed_methods' => ['*'],
```

## Step 3: Android Emulator Verification

### Check Emulator Status
```bash
adb devices
```
Expected: Should list one or more emulators

### Test Connection to Host
```bash
adb shell ping -c 1 10.0.2.2
```
Expected: Should return PING response (no errors)

### Test Endpoint Access
```bash
adb shell curl http://10.0.2.2:8000/api/register
```
Expected: Should return method not allowed (405) or similar

## Step 4: Run Flutter App

### Clean and Build
```bash
flutter clean
flutter pub get
```

### Run on Emulator
```bash
flutter run
```

Expected: App launches on emulator without build errors

### Check Debug Logs
Once app is running, look for:
```
📤 API POST: /api/register
   URL: http://10.0.2.2:8000/api/register
```

## Step 5: Test Registration - Valid Case

### Test Data
```
Name: Test User
Email: test@example.com
Phone: 255700123456
Password: TestPassword123
```

### Expected Flow
1. ✅ "📝 Starting registration flow..." in logs
2. ✅ "📤 API POST: /api/register" in logs
3. ✅ "✅ API Response (/api/register): 201" in logs
4. ✅ Screen navigates to OTP verification screen
5. ✅ UI displays OTP entry field

### Verify Database
```bash
php artisan tinker
>>> User::where('email', 'test@example.com')->first();
```

Expected:
- `is_verified` = false (0)
- `otp_code` = 6-digit number
- `otp_expires_at` = future timestamp

## Step 6: Test Registration - Timeout Error

### Simulate Timeout
1. Stop Laravel server: Press Ctrl+C
2. Click register button
3. Wait for response (should be ~30 seconds)

### Expected Behavior
1. ❌ "❌ API Error (/api/register): connectionTimeout" in logs
2. ✅ Error message displayed to user:
   ```
   "Server not responding. Please check your internet connection and try again."
   ```
3. ✅ Loading indicator disappears
4. ✅ Register button is clickable again

## Step 7: Test Registration - Validation Error

### Test Duplicate Email
1. Register again with same email as Step 5
2. Click register button

### Expected Behavior
1. ✅ "Status: 422" in logs
2. ✅ Error message displayed:
   ```
   "The email has already been taken."
   ```
3. ✅ Field is highlighted (if UI supports it)

### Test Weak Password
1. Enter password with less than 8 characters
2. Click register button

### Expected Behavior
1. ✅ Validation error (could be client-side or server-side)
2. ✅ Clear error message about password requirements

## Step 8: Test OTP Verification

### Get OTP Code
From database:
```bash
php artisan tinker
>>> User::where('email', 'test@example.com')->first()->otp_code
```

Or from logs if queue is running

### Enter OTP
1. Type OTP code in verification screen
2. Click verify button

### Expected Behavior
1. ✅ "🔐 AuthService.verifyOtp() called" in logs
2. ✅ "Status: 200" response code in logs
3. ✅ "✅ OTP verification successful" in logs
4. ✅ Token is returned and saved
5. ✅ Screen navigates to home
6. ✅ User is marked as verified in database

### Verify in Database
```bash
php artisan tinker
>>> User::where('email', 'test@example.com')->first()
```

Expected:
- `is_verified` = true (1)
- `otp_code` = null
- `otp_expires_at` = null
- `email_verified_at` = current timestamp

## Step 9: Test OTP Expiration

### Create User and Wait
1. Register new user
2. Note the OTP expiry time
3. Wait 10 minutes (or modify backend to shorter time for testing)
4. Try to verify with correct OTP

### Expected Behavior
1. ✅ "Invalid or expired OTP code" error message
2. ✅ "Status: 401" in logs

## Step 10: Test No Internet Error

### Disable Network (if on real device)
Turn off WiFi and mobile data

### Try Registration
Click register button

### Expected Behavior
1. ❌ "❌ API Error (/api/register): SocketException" in logs
2. ✅ Error message displayed:
   ```
   "No internet connection. Please check your network and try again."
   ```

(Skip on emulator as it's always connected)

## Step 11: Test Server Error (5xx)

### Trigger Server Error
Create a test endpoint that throws an error:

```php
// In routes/api.php
Route::post('/test-error', function() {
    throw new Exception('Test error');
});
```

Then modify registration temporarily to call this endpoint.

### Expected Behavior
1. ✅ "Status: 500" in logs
2. ✅ Error message displayed:
   ```
   "Server error. Please try again later."
   ```

Or if backend returns a message:
```
   "The error message from backend"
```

## Debug Output Examples

### Successful Registration
```
🔐 AuthService.register() called
   Endpoint: /api/register
   Fields: [name, email, phone, password, password_confirmation]

📤 API POST: /api/register
   URL: http://10.0.2.2:8000/api/register
   Body: {name: Test User, email: test@example.com, phone: 255700123456, password: ***, password_confirmation: ***}

✅ API Response (/api/register): 201
   Data: {message: Registration successful. OTP has been sent to your email., success: true, next: otp_verification, user_id: 1, user: {id: 1, name: Test User, email: test@example.com, phone: 255700123456}}

✅ Registration successful
   Response keys: [message, success, next, user_id, user]

📝 Starting registration flow...
✅ Registration response received
ℹ️ OTP verification required for user: 1
```

### Timeout Error
```
📤 API POST: /api/register
   URL: http://10.0.2.2:8000/api/register
   Body: {...}

❌ API Error (/api/register): connectionTimeout
   Status: null
   Error Type: DioExceptionType.connectionTimeout
   Message: Connection timeout

🔴 API Error:
   Status: 0
   Error Type: connectionTimeout
   Message: Connection timeout
   Response: null

❌ Registration failed with DioException
   Type: DioExceptionType.connectionTimeout
   Status: null

❌ Registration failed: Exception: Server not responding. Please check your internet connection and try again.
```

### Validation Error
```
❌ API Error (/api/register): httpResponse
   Status: 422
   Error Type: DioExceptionType.badResponse
   Message: null

🔴 API Error:
   Status: 422
   Error Type: badResponse
   Message: null
   Response: {message: Validation failed, errors: {email: [The email has already been taken.]}}

❌ Registration failed with DioException
   Type: DioExceptionType.badResponse
   Status: 422

❌ Registration failed: Exception: The email has already been taken.
```

## Automated Test Script

```bash
#!/bin/bash

echo "=== Registration Flow Test ==="

# Check code changes
echo "✓ Checking code changes..."
grep -q "10.0.2.2:8000/api" lib/core/api/api_config.dart && echo "  ✅ ApiConfig updated" || echo "  ❌ ApiConfig not updated"
grep -q "Duration(seconds: 30)" lib/core/api/api_service.dart && echo "  ✅ Timeout set to 30s" || echo "  ❌ Timeout not updated"
grep -q "is SocketException" lib/providers/auth_provider.dart && echo "  ✅ Socket error handling added" || echo "  ❌ Socket error handling missing"

# Check backend
echo "✓ Checking backend..."
curl -s http://localhost:8000/api/register -X POST | grep -q "json" && echo "  ✅ Backend is running" || echo "  ❌ Backend not responding"

# Check database
echo "✓ Checking database..."
php artisan tinker --execute="dd(Schema::getColumnListing('users'))" 2>/dev/null | grep -q "otp_code" && echo "  ✅ Database has OTP fields" || echo "  ❌ Database missing OTP fields"

echo "=== Test Complete ==="
```

## Troubleshooting

### Logs show "10.0.2.2: Name or service not known"
**Fix:** Emulator cannot reach host. Check:
- [ ] Emulator is running
- [ ] Firewall allows port 8000
- [ ] `adb shell ping 10.0.2.2` works

### Logs show "Connection refused"
**Fix:** Backend is not running. Check:
- [ ] `php artisan serve` is running
- [ ] Port is 8000 (not 8001 or other)
- [ ] No other process using port 8000

### Logs show "CORS error"
**Fix:** CORS not properly configured. Check:
- [ ] `config/cors.php` has correct settings
- [ ] `allowed_origins` includes '*'
- [ ] Headers are being sent correctly

### OTP not being received
**Fix:** Email/queue not configured. Check:
- [ ] `php artisan queue:work` is running (if async)
- [ ] Mail settings in `.env` are correct
- [ ] No errors in backend logs

### User appears verified immediately
**Fix:** Registration endpoint returning token. Check:
- [ ] Backend is checking OTP requirement
- [ ] `next: 'otp_verification'` is in response
- [ ] Token is not included before OTP verification

## Success Indicators

You'll know everything is working when:

✅ All code changes are applied (4 files)
✅ Flutter app builds without errors
✅ Registration with valid data navigates to OTP screen
✅ Timeout shows "Server not responding" message
✅ No internet shows "No internet connection" message
✅ Duplicate email shows specific error message
✅ OTP verification works and user is marked as verified
✅ Token is stored and used for subsequent API calls
✅ Debug logs are clear and informative (when enabled)
✅ All error messages are user-friendly and helpful

## Next Steps

1. ✅ Run through all 11 steps above
2. ✅ Verify each test case works as expected
3. ✅ Check debug logs match examples provided
4. ✅ Confirm database state after each operation
5. ✅ Test on both emulator and real device (if available)
6. ✅ Review error handling covers all scenarios
7. ✅ Test with various network conditions if possible
8. ✅ Disable debug logs for production
9. ✅ Update backend URL for production environment
10. ✅ Deploy to production with confidence

---

All tests should pass with the implemented changes!
