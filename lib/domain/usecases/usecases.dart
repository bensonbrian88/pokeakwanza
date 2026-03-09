// Use cases should contain single business logic operations
// They orchestrate between repositories and return Result types

import 'package:stynext/core/architecture/result.dart';
import 'package:stynext/core/architecture/repositories.dart';
import 'package:stynext/models/product.dart';
import 'package:stynext/models/category.dart';

/// Use case for fetching all products
class FetchProductsUseCase {
  final ProductRepository _repository;

  FetchProductsUseCase(this._repository);

  Future<Result<List<Product>>> call({
    int? page,
    String? search,
    String? categoryId,
    int? perPage,
  }) {
    return _repository.getProducts(
      page: page,
      search: search,
      categoryId: categoryId,
      perPage: perPage,
    );
  }
}

/// Use case for fetching new arrivals
class FetchNewArrivalsUseCase {
  final ProductRepository _repository;

  FetchNewArrivalsUseCase(this._repository);

  Future<Result<List<Product>>> call() {
    return _repository.getNewArrivals();
  }
}

/// Use case for fetching a single product
class FetchProductDetailUseCase {
  final ProductRepository _repository;

  FetchProductDetailUseCase(this._repository);

  Future<Result<Product>> call(int productId) {
    return _repository.getProductById(productId);
  }
}

/// Use case for adding product to cart
class AddToCartUseCase {
  final CartRepository _repository;

  AddToCartUseCase(this._repository);

  Future<Result<Map<String, dynamic>>> call({
    required int productId,
    required int quantity,
  }) {
    return _repository.addToCart(
      productId: productId,
      quantity: quantity,
    );
  }
}

/// Use case for updating cart item quantity
class UpdateCartQuantityUseCase {
  final CartRepository _repository;

  UpdateCartQuantityUseCase(this._repository);

  Future<Result<Map<String, dynamic>>> call({
    required int productId,
    required int quantity,
  }) {
    return _repository.updateQuantity(
      productId: productId,
      quantity: quantity,
    );
  }
}

/// Use case for removing item from cart
class RemoveFromCartUseCase {
  final CartRepository _repository;

  RemoveFromCartUseCase(this._repository);

  Future<Result<void>> call(int productId) {
    return _repository.removeFromCart(productId);
  }
}

/// Use case for getting current cart
class FetchCartUseCase {
  final CartRepository _repository;

  FetchCartUseCase(this._repository);

  Future<Result<Map<String, dynamic>>> call() {
    return _repository.getCart();
  }
}

/// Use case for clearing cart
class ClearCartUseCase {
  final CartRepository _repository;
  ClearCartUseCase(this._repository);
  Future<Result<void>> call() {
    return _repository.clearCart();
  }
}

/// Use case for checking out order
class CheckoutUseCase {
  final OrderRepository _repository;

  CheckoutUseCase(this._repository);

  Future<Result<int?>> call(String paymentMethod) {
    return _repository.checkout(paymentMethod);
  }
}

/// Use case for creating an order
class CreateOrderUseCase {
  final OrderRepository _repository;
  CreateOrderUseCase(this._repository);
  Future<Result<Map<String, dynamic>>> call(Map<String, dynamic> payload) {
    return _repository.createOrder(payload);
  }
}

/// Use case for fetching user orders
class FetchOrdersUseCase {
  final OrderRepository _repository;

  FetchOrdersUseCase(this._repository);

  Future<Result<List<dynamic>>> call() {
    return _repository.getOrders();
  }
}

/// Use case for fetching order details
class FetchOrderDetailUseCase {
  final OrderRepository _repository;

  FetchOrderDetailUseCase(this._repository);

  Future<Result<dynamic>> call(int orderId) {
    return _repository.getOrderDetail(orderId);
  }
}

/// Use case for user login
class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<Result<Map<String, dynamic>>> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email, password);
  }
}

/// Use case for user registration
class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<Result<Map<String, dynamic>>> call(Map<String, dynamic> data) {
    return _repository.register(data);
  }
}

/// Use case for logout
class LogoutUseCase {
  final AuthRepository _repository;
  LogoutUseCase(this._repository);
  Future<Result<void>> call() {
    return _repository.logout();
  }
}

/// Use case for getting categories
class FetchCategoriesUseCase {
  final CategoryRepository _repository;

  FetchCategoriesUseCase(this._repository);

  Future<Result<List<Category>>> call() {
    return _repository.getCategories();
  }
}

/// Use case for getting products by category
class FetchProductsByCategoryUseCase {
  final ProductRepository _repository;

  FetchProductsByCategoryUseCase(this._repository);

  Future<Result<List<Product>>> call(String categoryId) {
    return _repository.getProductsByCategory(categoryId);
  }
}

/// Use case for getting user data
class FetchUserUseCase {
  final UserRepository _repository;

  FetchUserUseCase(this._repository);

  Future<Result<dynamic>> call() {
    return _repository.getUser();
  }
}

/// Use case for updating user profile
class UpdateUserProfileUseCase {
  final UserRepository _repository;
  UpdateUserProfileUseCase(this._repository);
  Future<Result<dynamic>> call({String? name, String? phone}) {
    return _repository.updateProfile(name: name, phone: phone);
  }
}

/// Use case for getting saved addresses
class FetchAddressesUseCase {
  final ShippingAddressRepository _repository;

  FetchAddressesUseCase(this._repository);

  Future<Result<List<dynamic>>> call() {
    return _repository.getAddresses();
  }
}

/// Use case for adding new address
class AddAddressUseCase {
  final ShippingAddressRepository _repository;

  AddAddressUseCase(this._repository);

  Future<Result<dynamic>> call(Map<String, dynamic> data) {
    return _repository.addAddress(data);
  }
}

/// Use case for getting notifications
class FetchNotificationsUseCase {
  final NotificationRepository _repository;

  FetchNotificationsUseCase(this._repository);

  Future<Result<List<dynamic>>> call() {
    return _repository.getNotifications();
  }
}
