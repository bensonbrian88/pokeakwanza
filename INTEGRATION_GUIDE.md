# Production Tools Integration Guide

## Quick Start: Using Production Features

### 1. Display Cached Images
Instead of:
```dart
Image.network(url)
```

Use:
```dart
import 'package:stynext/widgets/cached_image.dart';

CachedImage(url, width: 200, height: 150)
```

### 2. Handle Global Errors
```dart
import 'package:stynext/core/error_handler.dart';

try {
  await apiService.someCall();
} catch (e) {
  final message = ErrorHandler.getErrorMessage(e);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message))
  );
}
```

### 3. Check Network Status
```dart
import 'package:stynext/core/network_service.dart';

final networkService = Provider.of<NetworkService>(context);

if (!networkService.isOnline) {
  isEnabled = false;  // Disable buttons
  showWarning('No internet connection');
}
```

### 4. Prevent Duplicate Submissions
```dart
import 'package:stynext/core/submission_guard.dart';

void _submitForm() async {
  try {
    await SubmissionGuard.executeOnce('form_key', () async {
      return await provider.submitForm(data);
    });
  } catch (e) {
    showError(ErrorHandler.getErrorMessage(e));
  }
}
```

### 5. Show Loading Shimmers
```dart
import 'package:stynext/widgets/shimmer_loaders.dart';

// For products
ProductShimmer(itemCount: 6, crossAxisCount: 2)

// For cart
CartItemShimmer(itemCount: 3)

// For home screen
const HomeScreenShimmer()
```

### 6. Animated Button with Loading State
```dart
import 'package:stynext/widgets/animated_custom_button.dart';

AnimatedCustomButton(
  label: 'Checkout',
  onPressed: _handleCheckout,
  isLoading: _isProcessing,
  gradient: true,
  icon: Icons.shopping_cart,
)
```

## Best Practices

### Network Calls
```dart
// Always wrap in error handler
try {
  final result = await apiService.fetchData();
  setState(() => data = result);
} catch (e) {
  final msg = ErrorHandler.getErrorMessage(e);
  showError(msg);
} finally {
  setState(() => isLoading = false);
}
```

### Form Submissions
```dart
// Always use SubmissionGuard for forms
void _submitForm() async {
  setState(() => isSubmitting = true);
  try {
    await SubmissionGuard.executeOnce('form_$_formId', () {
      return provider.submit(formData);
    });
    showSuccess('Form submitted successfully');
    Navigator.pop(context);
  } catch (e) {
    showError(ErrorHandler.getErrorMessage(e));
  } finally {
    setState(() => isSubmitting = false);
  }
}
```

### Image Display
```dart
// Always use CachedImage for network images
if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
  CachedImage(
    product.imageUrl!,
    width: 200,
    height: 150,
    borderRadius: BorderRadius.circular(12),
    fit: BoxFit.cover,
  )
} else {
  _buildPlaceholder()
}
```

## File Organization

New production files are located in:
```
lib/core/
  ├── error_handler.dart          # Global error handling
  ├── network_service.dart        # Connectivity monitoring
  └── submission_guard.dart       # Duplicate submission prevention

lib/widgets/
  ├── cached_image.dart           # Image caching widget
  ├── animated_custom_button.dart # Button with animations
  └── shimmer_loaders.dart        # Loading placeholders
```

## Debug Mode

To enable debug logging:
```dart
// In lib/config/api_config.dart
static const bool enableDebugLogs = true;  // Set to false in production
```

## Performance Tips

1. **Image Caching**: All network images are automatically cached
2. **Shimmer Loading**: Use shimmer for better perceived performance
3. **Prevent Redraws**: Use const constructors and keys
4. **Network Efficiency**: Disable debug logs in production
5. **Memory**: CachedImage limits disk cache to 512x512

## Debugging

### Check Network Status
```dart
final networkService = Provider.of<NetworkService>(context);
print('Online: ${networkService.isOnline}');
print('Connection type: ${networkService.lastResult}');
```

### View Error Details
```dart
ErrorHandler.logError('TAG', exception, stackTrace);
```

### Check Pending Requests
```dart
print('Pending: ${SubmissionGuard.isPending(\"key\")}');
SubmissionGuard.clear(\"key\");  // Clear if stuck
```

## Deployment

Before deploying to Play Store/App Store:

```dart
// Ensure debug logs are disabled
static const bool enableDebugLogs = false;

// Check all error handling is in place
// Verify image caching is working
// Test network timeouts
// Profile memory usage
```

## Support

For issues or improvements:
1. Check error logs: `ErrorHandler.logError()`
2. Monitor network: `NetworkService`
3. Review submission guard: `SubmissionGuard.isPending()`
4. Test with slow network (DevTools)

---

**Happy coding! Your users will appreciate the smooth, professional experience.** 🚀
