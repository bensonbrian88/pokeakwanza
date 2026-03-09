# Architecture Visualization

## Complete Clean Architecture Layers

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                                │
│                   (User Interface & State Management)                     │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  Screens              Widgets              Providers (to be updated)     │
│  ├── MainScreen       ├── ProductCard      ├── ProductProvider           │
│  ├── CartScreen       ├── CartItem         ├── CartProvider              │
│  ├── AuthScreen       ├── ErrorWidget      ├── AuthProvider              │
│  ├── OrderScreen      └── LoadingWidget    ├── OrderProvider             │
│  └── ...                                   └── ...                       │
│                                                                            │
│  Pattern: Provider uses GetIt to access use cases                         │
│  Example: final useCase = GetIt.instance<FetchProductsUseCase>();       │
│                                                                            │
└────────────────────────────┬─────────────────────────────────────────────┘
                             │ uses
                             ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                                         │
│                   (Business Logic & Use Cases)                            │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  File: lib/domain/usecases/usecases.dart                                 │
│                                                                            │
│  Use Cases (20+):                                                        │
│  ├── FetchProductsUseCase                                                │
│  ├── FetchProductDetailUseCase                                           │
│  ├── FetchNewArrivalsUseCase                                             │
│  ├── AddToCartUseCase                                                    │
│  ├── UpdateCartQuantityUseCase                                           │
│  ├── RemoveFromCartUseCase                                               │
│  ├── FetchCartUseCase                                                    │
│  ├── CheckoutUseCase                                                     │
│  ├── FetchOrdersUseCase                                                  │
│  ├── FetchOrderDetailUseCase                                             │
│  ├── LoginUseCase                                                        │
│  ├── RegisterUseCase                                                     │
│  ├── FetchUserUseCase                                                    │
│  ├── FetchCategoriesUseCase                                              │
│  ├── FetchProductsByCategoryUseCase                                      │
│  ├── FetchAddressesUseCase                                               │
│  ├── AddAddressUseCase                                                   │
│  ├── FetchNotificationsUseCase                                           │
│  └── ...                                                                 │
│                                                                            │
│  Pattern: Each use case wraps ONE repository operation                    │
│  class FetchProductsUseCase {                                            │
│    Future<Result<List<Product>>> call({int page = 1}) {                  │
│      return _repository.getProducts(page: page);                         │
│    }                                                                      │
│  }                                                                        │
│                                                                            │
└────────────────────────────┬─────────────────────────────────────────────┘
                             │ depends on
                             ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                      DATA LAYER                                           │
│                   (Repositories & Data Access)                            │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  Repository Interfaces: lib/core/architecture/repositories.dart          │
│  ├── ProductRepository                                                   │
│  ├── CategoryRepository                                                  │
│  ├── CartRepository                                                      │
│  ├── OrderRepository                                                     │
│  ├── AuthRepository                                                      │
│  ├── UserRepository                                                      │
│  ├── ShippingAddressRepository                                           │
│  └── NotificationRepository                                              │
│                                                                            │
│  Repository Implementations: lib/data/repositories/impl/                 │
│  │                                                                        │
│  ├── product_repository_impl.dart                                        │
│  │   ├── ProductRepositoryImpl                                           │
│  │   │   ├── getProducts()                                              │
│  │   │   ├── getProductById()                                           │
│  │   │   ├── getNewArrivals()                                           │
│  │   │   ├── getProductsByCategory()                                    │
│  │   │   └── getFlashSale()                                             │
│  │   ├── CategoryRepositoryImpl                                          │
│  │   │   ├── getCategories()                                            │
│  │   │   └── getCategoryById()                                          │
│  │   └── ExceptionMapper                                                │
│  │       └── map(DioException) → AppException                           │
│  │                                                                        │
│  ├── cart_order_repository_impl.dart                                     │
│  │   ├── CartRepositoryImpl                                              │
│  │   │   ├── getCart() [with null safety]                               │
│  │   │   ├── addToCart() [with qty validation]                          │
│  │   │   ├── updateQuantity() [with qty validation]                     │
│  │   │   ├── removeFromCart()                                           │
│  │   │   ├── getCartSummary()                                           │
│  │   │   └── clearCart()                                                │
│  │   └── OrderRepositoryImpl                                             │
│  │       ├── getOrders()                                                │
│  │       ├── checkout() [validates payment method]                      │
│  │       ├── getOrderDetail()                                           │
│  │       ├── createOrder()                                              │
│  │       └── confirmOrder()                                             │
│  │                                                                        │
│  └── auth_user_repository_impl.dart                                      │
│      ├── AuthRepositoryImpl                                              │
│      │   ├── login() [validates email]                                  │
│      │   ├── register() [validates password/name]                       │
│      │   ├── firebaseLogin()                                            │
│      │   ├── verifyOtp() [validates OTP format]                         │
│      │   └── getPhoneCodes()                                            │
│      ├── UserRepositoryImpl                                              │
│      │   ├── getUser()                                                  │
│      │   └── updateProfile()                                            │
│      ├── ShippingAddressRepositoryImpl                                   │
│      │   ├── getAddresses()                                             │
│      │   ├── addAddress() [validates address fields]                    │
│      │   ├── updateAddress()                                            │
│      │   └── deleteAddress()                                            │
│      └── NotificationRepositoryImpl                                      │
│          ├── getNotifications()                                         │
│          └── markAsRead()                                               │
│                                                                            │
│  Pattern: Repositories handle error mapping & validation                 │
│  try {                                                                   │
│    final response = await _api.call();                                   │
│    return Success(response);                                             │
│  } catch (e, st) {                                                       │
│    return Failure(ExceptionMapper.map(e, st));                          │
│  }                                                                        │
│                                                                            │
└────────────────────────────┬─────────────────────────────────────────────┘
                             │ uses
                             ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                      CORE LAYER                                           │
│              (Infrastructure & Cross-Cutting Concerns)                    │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  RESULT TYPE: lib/core/architecture/result.dart                          │
│  ┌─────────────────────────────────────────────────────────┐             │
│  │ sealed class Result<T>                                  │             │
│  ├─────────────────────────────────────────────────────────┤             │
│  │ final class Success<T> implements Result<T> {           │             │
│  │   final T value;                                        │             │
│  │   • fold(onSuccess, onFailure)                          │             │
│  │   • map(transform)                                      │             │
│  │   • getOrNull() → T?                                    │             │
│  │   • isSuccess → bool                                    │             │
│  │ }                                                        │             │
│  │                                                          │             │
│  │ final class Failure<T> implements Result<T> {           │             │
│  │   final AppException exception;                         │             │
│  │   • fold(onSuccess, onFailure)                          │             │
│  │   • mapError(transform)                                 │             │
│  │   • getErrorOrNull() → AppException?                    │             │
│  │   • isFailure → bool                                    │             │
│  │ }                                                        │             │
│  └─────────────────────────────────────────────────────────┘             │
│                                                                            │
│  EXCEPTIONS: lib/core/architecture/exceptions.dart                       │
│  ┌─────────────────────────────────────────────────────────┐             │
│  │ AppException (base) with stackTrace property           │             │
│  ├─────────────────────────────────────────────────────────┤             │
│  │ NetworkException       → Network-related (timeout, DNS) │             │
│  │ ServerException        → HTTP errors (4xx, 5xx)         │             │
│  │ ValidationException    → Input validation errors        │             │
│  │ DataException          → JSON parsing/null safety      │             │
│  │ CacheException         → Cache read/write failures      │             │
│  │ AuthException          → Authentication issues         │             │
│  │ UnknownException       → Catch-all for unknown errors   │             │
│  └─────────────────────────────────────────────────────────┘             │
│                                                                            │
│  DEPENDENCY INJECTION: lib/core/di/service_locator.dart                  │
│  ┌─────────────────────────────────────────────────────────┐             │
│  │ setupServiceLocator() {                                 │             │
│  │   // Register all repositories (8)                      │             │
│  │   getIt.registerSingleton<ProductRepository>(() => ...) │             │
│  │                                                          │             │
│  │   // Register all use cases (20+)                       │             │
│  │   getIt.registerSingleton<FetchProductsUseCase>(() => ...) │          │
│  │ }                                                        │             │
│  │                                                          │             │
│  │ Usage: GetIt.instance<UseCase>()                        │             │
│  └─────────────────────────────────────────────────────────┘             │
│                                                                            │
│  API SERVICE: lib/core/api/api_service.dart (existing)                   │
│  └─ Handles HTTP calls (unchanged)                                       │
│                                                                            │
│  OTHER SERVICES:                                                         │
│  ├── TokenService (auth token management)                                │
│  ├── NetworkService (connectivity checks)                                │
│  ├── NavigationService (route management)                                │
│  └── ...                                                                 │
│                                                                            │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Example: Adding Product to Cart

```
┌─ USER CLICKS "ADD TO CART" ─────────────────────────────────────┐
│                                                                    │
│  PRESENTATION LAYER:                                             │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ ProductDetailsScreen.dart                                  │ │
│  │ • User taps "Add to Cart" button                           │ │
│  │ • Calls: cartProvider.addToCart(productId, quantity)      │ │
│  └────────────────────────────────────────────────────────────┘ │
│                        ▼                                          │
│  PRESENTATION LAYER:                                             │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ CartProvider.addToCart()                                   │ │
│  │ • Sets _isLoading = true                                  │ │
│  │ • Gets use case from GetIt: AddToCartUseCase              │ │
│  │ • Calls: await _addToCartUseCase.call(productId, qty)    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                        ▼                                          │
│  DOMAIN LAYER:                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ AddToCartUseCase                                           │ │
│  │ • Receives productId, quantity                             │ │
│  │ • Calls: _repository.addToCart(productId, qty)           │ │
│  │ • Returns Result<void>                                    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                        ▼                                          │
│  DATA LAYER:                                                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ CartRepositoryImpl.addToCart()                              │ │
│  │ • Validates: quantity > 0                                 │ │
│  │ • Makes API call: POST /cart/add                          │ │
│  │                        ▼                                    │ │
│  │                   ApiService.addToCart()                   │ │
│  │                        ▼                                    │ │
│  │                   DioException (if any)                    │ │
│  │                        ▼                                    │ │
│  │ • ExceptionMapper.map(exception)                          │ │
│  │ • Maps DioException → AppException                        │ │
│  │ • Returns Result<void>                                    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                        ▼                                          │
│  DOMAIN LAYER: (back to use case)                               │
│  └─ Returns Result<void>                                        │
│                        ▼                                          │
│  PRESENTATION LAYER: (back to provider)                         │
│  │                                                               │
│  │ CartProvider.fold() result:                                 │
│  │                                                               │
│  │ ✅ SUCCESS PATH:                                            │
│  │ • _error = null                                             │
│  │ • Calls fetchCart() to refresh                              │
│  │ • _isLoading = false                                        │
│  │ • notifyListeners() → UI updates                            │
│  │ • UserScreen shows "Added to cart"                          │
│  │                                                               │
│  │ ❌ FAILURE PATH:                                            │
│  │ • _error = error.message                                    │
│  │ • _isLoading = false                                        │
│  │ • notifyListeners() → UI updates                            │
│  │ • UserScreen shows error message                            │
│  │   (e.g., "Network error" or "Invalid quantity")             │
│  │                                                               │
└─────────────────────────────────────────────────────────────────┘

RESULT:
• On Success: Product added to cart, cart updates, user sees confirmation
• On Failure: Error message shown, cart unchanged, user can retry
• Type-Safe: Compiler ensures error is handled (Result<T> forces .fold())
• Traceable: Stack trace preserved through exception mapping
```

---

## Dependency Injection Graph

```
┌─────────────────────────────────────────────────────┐
│         SERVICE LOCATOR (GetIt)                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  REPOSITORIES (depends on ApiService):             │
│  ├─→ ProductRepository                             │
│  ├─→ CategoryRepository                            │
│  ├─→ CartRepository                                │
│  ├─→ OrderRepository                               │
│  ├─→ AuthRepository                                │
│  ├─→ UserRepository                                │
│  ├─→ ShippingAddressRepository                     │
│  └─→ NotificationRepository                        │
│                                                     │
│       Each repository dependency:                  │
│       Repository ← ApiService                      │
│                                                     │
│                                                     │
│  USE CASES (depends on Repositories):              │
│  ├─→ FetchProductsUseCase ← ProductRepository      │
│  ├─→ AddToCartUseCase ← CartRepository             │
│  ├─→ CheckoutUseCase ← OrderRepository             │
│  ├─→ LoginUseCase ← AuthRepository                 │
│  ├─→ FetchUserUseCase ← UserRepository             │
│  ├─→ FetchAddressesUseCase ← ShippingAddressRep   │
│  ├─→ FetchNotificationsUseCase ← NotificationRep  │
│  └─→ ... 20+ more use cases                        │
│                                                     │
│       Each use case dependency:                    │
│       UseCase ← Repository                         │
│                                                     │
│                                                     │
│  DEPENDENCY CHAIN (Example):                       │
│  GetIt.instance<AddToCartUseCase>()                │
│    ↓ needs                                         │
│  CartRepository                                    │
│    ↓ needs                                         │
│  ApiService                                        │
│    ↓ uses                                          │
│  Dio HTTP client                                   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Error Handling Flow

```
┌─ ERROR OCCURS IN REPOSITORY ───────────────────────┐
│                                                      │
│  API Call Throws Exception (DioException)          │
│              ▼                                       │
│  try/catch block catches:                          │
│              ▼                                       │
│  ExceptionMapper.map(exception, stackTrace)        │
│              ▼                                       │
│  Maps DioException type to AppException:           │
│                                                     │
│  DioExceptionType.connectTimeout                   │
│     → NetworkException("Connection timeout")       │
│                                                     │
│  DioExceptionType.receiveTimeout                   │
│     → NetworkException("Request timeout")          │
│                                                     │
│  DioExceptionType.badResponse(400)                 │
│     → ValidationException("Bad request")           │
│                                                     │
│  DioExceptionType.badResponse(401)                 │
│     → AuthException("Unauthorized")                │
│                                                     │
│  DioExceptionType.badResponse(403)                 │
│     → AuthException("Forbidden")                   │
│                                                     │
│  DioExceptionType.badResponse(500)                 │
│     → ServerException("Internal server error")     │
│                                                     │
│  Unknown exception                                 │
│     → UnknownException(message, stackTrace)        │
│              ▼                                       │
│  Wrapped in Failure<T>:                            │
│  return Failure(mappedException)                   │
│              ▼                                       │
│  Use case receives Result<T>                       │
│              ▼                                       │
│  Provider receives Result<T>                       │
│              ▼                                       │
│  result.fold(onSuccess, onFailure):               │
│              ▼                                       │
│  Provider displays:                                │
│  error.message → User-friendly error in UI         │
│  error.stackTrace → Logged for debugging           │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## File Structure Tree

```
lib/
├── core/
│   ├── architecture/
│   │   ├── result.dart                    ← Result<T> type
│   │   ├── exceptions.dart                ← Exception hierarchy
│   │   └── repositories.dart              ← Repository interfaces
│   ├── api/
│   │   ├── api_service.dart               ← API client
│   │   └── interceptors.dart
│   ├── di/
│   │   └── service_locator.dart           ← Dependency injection
│   ├── theme/
│   ├── utils/
│   └── ...
│
├── data/
│   └── repositories/
│       └── impl/
│           ├── product_repository_impl.dart
│           ├── cart_order_repository_impl.dart
│           └── auth_user_repository_impl.dart
│
├── domain/
│   └── usecases/
│       └── usecases.dart                  ← 20+ use cases
│
├── presentation/
│   ├── screens/                           ← UI screens (unchanged)
│   ├── providers/                         ← To be updated
│   ├── widgets/                           ← Reusable widgets
│   └── dialogs/
│
├── models/                                ← Data models (unchanged)
├── config/
├── services/
├── utils/
├── routes.dart
└── main.dart                              ← Updated to init DI
```

---

**This architecture provides enterprise-grade scalability, testability, and maintainability!**
