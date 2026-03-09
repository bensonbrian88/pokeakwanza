# Provider Integration Guide

This guide explains how to integrate the clean architecture repositories and use cases into your existing providers.

## Overview

The providers are the bridge between the presentation layer (UI) and the domain layer (use cases). Instead of directly calling API services, providers now use use cases from the dependency injection container.

---

## Step-by-Step Integration

### Phase 1: ProductProvider

#### Current Implementation Issue
- Direct API calls in `ProductProvider`
- No exception handling standardization
- Tightly coupled to `ApiService`

#### Updated Implementation

```dart
// lib/providers/product_provider.dart
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../domain/usecases/usecases.dart';
import '../models/product_model.dart';
import '../core/architecture/exceptions.dart';

class ProductProvider extends ChangeNotifier {
  // Dependencies injected from service locator
  late final FetchProductsUseCase _fetchProductsUseCase;
  late final FetchNewArrivalsUseCase _fetchNewArrivalsUseCase;
  late final FetchProductDetailUseCase _fetchProductDetailUseCase;
  late final FetchProductsByCategoryUseCase _fetchProductsByCategoryUseCase;
  late final FetchFlashSaleUseCase _fetchFlashSaleUseCase;

  // State
  List<Product> _products = [];
  List<Product> _newArrivals = [];
  List<Product> _flashSaleProducts = [];
  Product? _selectedProduct;
  String? _error;
  bool _isLoading = false;

  // Getters
  List<Product> get products => _products;
  List<Product> get newArrivals => _newArrivals;
  List<Product> get flashSaleProducts => _flashSaleProducts;
  Product? get selectedProduct => _selectedProduct;
  String? get error => _error;
  bool get isLoading => _isLoading;

  // Constructor with dependency injection
  ProductProvider() {
    _fetchProductsUseCase = GetIt.instance<FetchProductsUseCase>();
    _fetchNewArrivalsUseCase = GetIt.instance<FetchNewArrivalsUseCase>();
    _fetchProductDetailUseCase = GetIt.instance<FetchProductDetailUseCase>();
    _fetchProductsByCategoryUseCase = 
        GetIt.instance<FetchProductsByCategoryUseCase>();
    _fetchFlashSaleUseCase = GetIt.instance<FetchFlashSaleUseCase>();
  }

  // Fetch products with error handling
  Future<void> fetchProducts({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _fetchProductsUseCase.call(page: page);
    
    result.fold(
      onSuccess: (products) {
        _products = products;
        _error = null;
      },
      onFailure: (error) {
        _products = [];
        _error = _formatErrorMessage(error);
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Fetch new arrivals
  Future<void> fetchNewArrivals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _fetchNewArrivalsUseCase.call();
    
    result.fold(
      onSuccess: (products) {
        _newArrivals = products;
        _error = null;
      },
      onFailure: (error) {
        _newArrivals = [];
        _error = _formatErrorMessage(error);
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Fetch product details
  Future<void> fetchProductDetail(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _fetchProductDetailUseCase.call(productId: productId);
    
    result.fold(
      onSuccess: (product) {
        _selectedProduct = product;
        _error = null;
      },
      onFailure: (error) {
        _selectedProduct = null;
        _error = _formatErrorMessage(error);
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Fetch products by category
  Future<void> fetchProductsByCategory(String categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = 
        await _fetchProductsByCategoryUseCase.call(categoryId: categoryId);
    
    result.fold(
      onSuccess: (products) {
        _products = products;
        _error = null;
      },
      onFailure: (error) {
        _products = [];
        _error = _formatErrorMessage(error);
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Fetch flash sale products
  Future<void> fetchFlashSale() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _fetchFlashSaleUseCase.call();
    
    result.fold(
      onSuccess: (products) {
        _flashSaleProducts = products;
        _error = null;
      },
      onFailure: (error) {
        _flashSaleProducts = [];
        _error = _formatErrorMessage(error);
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Helper to format error messages for UI
  String _formatErrorMessage(AppException error) {
    if (error is NetworkException) {
      return 'Network error. Please check your connection.';
    } else if (error is ServerException) {
      return error.message;
    } else if (error is CacheException) {
      return 'Cache error. Please try again.';
    } else {
      return error.message;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
```

#### Update main.dart providers

```dart
// OLD
ChangeNotifierProvider(create: (_) => ProductProvider()),

// NEW
ChangeNotifierProvider(create: (_) => ProductProvider()),
```

The constructor already handles dependency injection internally via `GetIt`.

---

### Phase 2: CartProvider

#### Updated Implementation

```dart
// lib/providers/cart_provider.dart
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../domain/usecases/usecases.dart';
import '../models/product_model.dart';
import '../core/architecture/exceptions.dart';

class CartProvider extends ChangeNotifier {
  // Dependencies
  late final FetchCartUseCase _fetchCartUseCase;
  late final AddToCartUseCase _addToCartUseCase;
  late final UpdateCartQuantityUseCase _updateQuantityUseCase;
  late final RemoveFromCartUseCase _removeFromCartUseCase;
  late final CheckoutUseCase _checkoutUseCase;

  // State
  List<Map<String, dynamic>> _cartItems = [];
  double _totalPrice = 0.0;
  String? _error;
  bool _isLoading = false;

  // Getters
  List<Map<String, dynamic>> get cartItems => _cartItems;
  double get totalPrice => _totalPrice;
  String? get error => _error;
  bool get isLoading => _isLoading;
  int get itemCount => _cartItems.length;

  CartProvider() {
    _fetchCartUseCase = GetIt.instance<FetchCartUseCase>();
    _addToCartUseCase = GetIt.instance<AddToCartUseCase>();
    _updateQuantityUseCase = GetIt.instance<UpdateCartQuantityUseCase>();
    _removeFromCartUseCase = GetIt.instance<RemoveFromCartUseCase>();
    _checkoutUseCase = GetIt.instance<CheckoutUseCase>();
  }

  // Fetch cart
  Future<void> fetchCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _fetchCartUseCase.call();
    
    result.fold(
      onSuccess: (items) {
        _cartItems = items;
        _calculateTotal();
        _error = null;
      },
      onFailure: (error) {
        _cartItems = [];
        _totalPrice = 0.0;
        _error = _formatErrorMessage(error);
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Add to cart
  Future<void> addToCart(String productId, int quantity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _addToCartUseCase.call(
      productId: productId,
      quantity: quantity,
    );
    
    result.fold(
      onSuccess: (_) {
        _error = null;
        fetchCart(); // Refresh cart
      },
      onFailure: (error) {
        _error = _formatErrorMessage(error);
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Update quantity
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _updateQuantityUseCase.call(
      cartItemId: cartItemId,
      quantity: quantity,
    );
    
    result.fold(
      onSuccess: (_) {
        _error = null;
        fetchCart();
      },
      onFailure: (error) {
        _error = _formatErrorMessage(error);
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Remove from cart
  Future<void> removeFromCart(String cartItemId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _removeFromCartUseCase.call(cartItemId: cartItemId);
    
    result.fold(
      onSuccess: (_) {
        _error = null;
        fetchCart();
      },
      onFailure: (error) {
        _error = _formatErrorMessage(error);
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Checkout
  Future<String?> checkout(String paymentMethod) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _checkoutUseCase.call(paymentMethod: paymentMethod);
    
    String? orderId;
    result.fold(
      onSuccess: (id) {
        _error = null;
        orderId = id;
        _cartItems = [];
        _totalPrice = 0.0;
      },
      onFailure: (error) {
        _error = _formatErrorMessage(error);
      },
    );

    _isLoading = false;
    notifyListeners();
    
    return orderId;
  }

  void _calculateTotal() {
    _totalPrice = _cartItems.fold(0.0, (sum, item) {
      final price = (item['price'] as num?) ?? 0.0;
      final quantity = (item['quantity'] as num?) ?? 1;
      return sum + (price * quantity);
    });
  }

  String _formatErrorMessage(AppException error) {
    if (error is ValidationException) {
      return 'Invalid input: ${error.message}';
    } else if (error is NetworkException) {
      return 'Network error. Please check your connection.';
    } else {
      return error.message;
    }
  }

  void clearCart() {
    _cartItems = [];
    _totalPrice = 0.0;
    notifyListeners();
  }
}
```

---

### Phase 3: AuthProvider

```dart
// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../domain/usecases/usecases.dart';
import '../models/user_model.dart';
import '../core/architecture/exceptions.dart';

class AuthProvider extends ChangeNotifier {
  // Dependencies
  late final LoginUseCase _loginUseCase;
  late final RegisterUseCase _registerUseCase;
  late final FetchUserUseCase _fetchUserUseCase;

  // State
  UserModel? _user;
  bool _isAuthenticated = false;
  String? _error;
  bool _isLoading = false;

  // Getters
  UserModel? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loginUseCase = GetIt.instance<LoginUseCase>();
    _registerUseCase = GetIt.instance<RegisterUseCase>();
    _fetchUserUseCase = GetIt.instance<FetchUserUseCase>();
  }

  // Initialize auth state
  Future<void> init() async {
    // Check if user already logged in
    final result = await _fetchUserUseCase.call();
    
    result.fold(
      onSuccess: (user) {
        _user = user;
        _isAuthenticated = true;
      },
      onFailure: (error) {
        _user = null;
        _isAuthenticated = false;
      },
    );
    
    notifyListeners();
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _loginUseCase.call(
      email: email,
      password: password,
    );
    
    bool success = false;
    result.fold(
      onSuccess: (user) {
        _user = user;
        _isAuthenticated = true;
        _error = null;
        success = true;
      },
      onFailure: (error) {
        _user = null;
        _isAuthenticated = false;
        _error = _formatErrorMessage(error);
      },
    );

    _isLoading = false;
    notifyListeners();
    
    return success;
  }

  // Register
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _registerUseCase.call(
      name: name,
      email: email,
      password: password,
    );
    
    bool success = false;
    result.fold(
      onSuccess: (user) {
        _user = user;
        _isAuthenticated = true;
        _error = null;
        success = true;
      },
      onFailure: (error) {
        _user = null;
        _isAuthenticated = false;
        _error = _formatErrorMessage(error);
      },
    );

    _isLoading = false;
    notifyListeners();
    
    return success;
  }

  String _formatErrorMessage(AppException error) {
    if (error is AuthException) {
      return error.message;
    } else if (error is ValidationException) {
      return 'Invalid input: ${error.message}';
    } else if (error is NetworkException) {
      return 'Network error. Please check your connection.';
    } else {
      return error.message;
    }
  }

  void logout() {
    _user = null;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }
}
```

---

### Phase 4: OrderProvider

```dart
// lib/providers/order_provider.dart
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../domain/usecases/usecases.dart';
import '../core/architecture/exceptions.dart';

class OrderProvider extends ChangeNotifier {
  // Dependencies
  late final FetchOrdersUseCase _fetchOrdersUseCase;
  late final FetchOrderDetailUseCase _fetchOrderDetailUseCase;

  // State
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _selectedOrder;
  String? _error;
  bool _isLoading = false;

  // Getters
  List<Map<String, dynamic>> get orders => _orders;
  Map<String, dynamic>? get selectedOrder => _selectedOrder;
  String? get error => _error;
  bool get isLoading => _isLoading;

  OrderProvider() {
    _fetchOrdersUseCase = GetIt.instance<FetchOrdersUseCase>();
    _fetchOrderDetailUseCase = GetIt.instance<FetchOrderDetailUseCase>();
  }

  // Fetch orders
  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _fetchOrdersUseCase.call();
    
    result.fold(
      onSuccess: (orders) {
        _orders = orders;
        _error = null;
      },
      onFailure: (error) {
        _orders = [];
        _error = _formatErrorMessage(error);
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Fetch order detail
  Future<void> fetchOrderDetail(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _fetchOrderDetailUseCase.call(orderId: orderId);
    
    result.fold(
      onSuccess: (order) {
        _selectedOrder = order;
        _error = null;
      },
      onFailure: (error) {
        _selectedOrder = null;
        _error = _formatErrorMessage(error);
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  String _formatErrorMessage(AppException error) {
    if (error is NetworkException) {
      return 'Network error. Please check your connection.';
    } else {
      return error.message;
    }
  }
}
```

---

### Phase 5: CategoryProvider

```dart
// lib/providers/category_provider.dart
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../domain/usecases/usecases.dart';
import '../models/category_model.dart';
import '../core/architecture/exceptions.dart';

class CategoryProvider extends ChangeNotifier {
  // Dependencies
  late final FetchCategoriesUseCase _fetchCategoriesUseCase;

  // State
  List<Category> _categories = [];
  Category? _selectedCategory;
  String? _error;
  bool _isLoading = false;

  // Getters
  List<Category> get categories => _categories;
  Category? get selectedCategory => _selectedCategory;
  String? get error => _error;
  bool get isLoading => _isLoading;

  CategoryProvider() {
    _fetchCategoriesUseCase = GetIt.instance<FetchCategoriesUseCase>();
  }

  // Fetch categories
  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _fetchCategoriesUseCase.call();
    
    result.fold(
      onSuccess: (categories) {
        _categories = categories;
        _error = null;
      },
      onFailure: (error) {
        _categories = [];
        _error = _formatErrorMessage(error);
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Select category
  void selectCategory(Category category) {
    _selectedCategory = category;
    notifyListeners();
  }

  String _formatErrorMessage(AppException error) {
    if (error is NetworkException) {
      return 'Network error. Please check your connection.';
    } else {
      return error.message;
    }
  }
}
```

---

## Migration Checklist

- [ ] **Phase 1**: Update `ProductProvider` with use case injection
- [ ] **Phase 2**: Update `CartProvider` with use case injection
- [ ] **Phase 3**: Update `AuthProvider` with use case injection
- [ ] **Phase 4**: Update `OrderProvider` with use case injection
- [ ] **Phase 5**: Update `CategoryProvider` with use case injection
- [ ] **Phase 6**: Update remaining providers (shipping address, notifications, etc.)
- [ ] Test all providers work correctly with new architecture
- [ ] Verify error messages display properly
- [ ] Test cart operations (add, update, remove)
- [ ] Test authentication flow
- [ ] Test product loading

---

## Testing the Integration

### Test 1: Verify Service Locator Initialized
```dart
// In a test or debug screen
import 'package:get_it/get_it.dart';
import 'domain/usecases/usecases.dart';

void testDI() {
  try {
    final useCase = GetIt.instance<FetchProductsUseCase>();
    print('✅ Service locator initialized correctly');
  } catch (e) {
    print('❌ Service locator not initialized: $e');
  }
}
```

### Test 2: Provider Integration
```dart
// In a test
void main() {
  testWidgets('ProductProvider fetches products', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProductProvider()),
        ],
        child: const TestApp(),
      ),
    );

    final provider = 
        tester.widget<ProductProvider>(find.byType(ProductProvider));
    
    await provider.fetchProducts();
    expect(provider.isLoading, false);
    expect(provider.products, isNotEmpty);
  });
}
```

---

## Troubleshooting

### Issue: "Service locator not initialized"
**Solution**: Ensure `setupServiceLocator()` is called in `main()` before creating providers.

### Issue: "Use case not found in service locator"
**Solution**: Check that the use case is registered in `service_locator.dart` and the import is correct.

### Issue: "Null reference error in provider"
**Solution**: Ensure use cases are initialized in constructor with `GetIt.instance<UseCase>()`.

### Issue: "State not updating"
**Solution**: Always call `notifyListeners()` after updating state.

---

## Benefits of This Integration

✅ **Centralized Error Handling**: All errors go through exception hierarchy
✅ **Testability**: Use cases can be mocked in tests
✅ **Maintainability**: Clear separation between UI and business logic
✅ **Reusability**: Same use case can be called from multiple screens
✅ **Type Safety**: Result<T> ensures proper error handling

---

**Once all providers are updated, the app will have a fully enterprise-grade clean architecture!**
