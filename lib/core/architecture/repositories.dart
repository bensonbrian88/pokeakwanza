import 'package:stynext/core/architecture/result.dart';
import 'package:stynext/models/product.dart';
import 'package:stynext/models/category.dart';

/// Repository interface for product operations
/// Abstracts the data layer from business logic
abstract class ProductRepository {
  /// Get all products with optional filtering
  Future<Result<List<Product>>> getProducts({
    int? page,
    String? search,
    String? categoryId,
    int? perPage,
  });

  /// Get product by ID
  Future<Result<Product>> getProductById(int id);

  /// Get new arrivals
  Future<Result<List<Product>>> getNewArrivals();

  /// Get products by category
  Future<Result<List<Product>>> getProductsByCategory(String categoryId);

  /// Get flash sale products
  Future<Result<List<Product>>> getFlashSale();
}

/// Repository interface for category operations
abstract class CategoryRepository {
  /// Get all categories
  Future<Result<List<Category>>> getCategories();

  /// Get category by ID
  Future<Result<Category>> getCategoryById(String id);
}

/// Repository interface for cart operations
abstract class CartRepository {
  /// Get current cart
  Future<Result<Map<String, dynamic>>> getCart();

  /// Add product to cart
  Future<Result<Map<String, dynamic>>> addToCart({
    required int productId,
    required int quantity,
  });

  /// Update product quantity in cart
  Future<Result<Map<String, dynamic>>> updateQuantity({
    required int productId,
    required int quantity,
  });

  /// Remove product from cart
  Future<Result<void>> removeFromCart(int productId);

  /// Get cart summary
  Future<Result<Map<String, dynamic>>> getCartSummary();

  /// Clear entire cart
  Future<Result<void>> clearCart();
}

/// Repository interface for order operations
abstract class OrderRepository {
  /// Get all orders for current user
  Future<Result<List<dynamic>>> getOrders();

  /// Checkout and place order
  Future<Result<int?>> checkout(String paymentMethod);

  /// Get order detail by ID
  Future<Result<dynamic>> getOrderDetail(int orderId);

  /// Create new order
  Future<Result<Map<String, dynamic>>> createOrder(
    Map<String, dynamic> payload,
  );

  /// Confirm order
  Future<Result<Map<String, dynamic>>> confirmOrder(int orderId);
}

/// Repository interface for authentication
abstract class AuthRepository {
  /// User login
  Future<Result<Map<String, dynamic>>> login(
    String email,
    String password,
  );

  /// User registration
  Future<Result<Map<String, dynamic>>> register(
    Map<String, dynamic> payload,
  );

  /// Firebase login
  Future<Result<Map<String, dynamic>>> firebaseLogin({
    required String firebaseUid,
    String? phone,
  });

  /// Verify OTP
  Future<Result<Map<String, dynamic>>> verifyOtp(
    int userId,
    String otpCode,
  );

  /// Resend OTP
  Future<Result<Map<String, dynamic>>> resendOtp(int userId);

  /// Get phone codes
  Future<Result<List<dynamic>>> getPhoneCodes();

  /// Logout
  Future<Result<void>> logout();
}

/// Repository interface for user profile
abstract class UserRepository {
  /// Get current authenticated user
  Future<Result<dynamic>> getUser();

  /// Update user profile
  Future<Result<dynamic>> updateProfile({
    String? name,
    String? phone,
  });

  /// Get user settings
  Future<Result<Map<String, dynamic>>> getUserSettings();
}

/// Repository interface for shipping addresses
abstract class ShippingAddressRepository {
  /// Get all saved addresses
  Future<Result<List<dynamic>>> getAddresses();

  /// Add new address
  Future<Result<dynamic>> addAddress(Map<String, dynamic> payload);

  /// Update existing address
  Future<Result<dynamic>> updateAddress(
    int id,
    Map<String, dynamic> payload,
  );

  /// Delete address
  Future<Result<void>> deleteAddress(int id);
}

/// Repository interface for notifications
abstract class NotificationRepository {
  /// Get all notifications
  Future<Result<List<dynamic>>> getNotifications();

  /// Mark notifications as read
  Future<Result<void>> markNotificationsAsRead();
}
