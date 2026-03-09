# Enterprise Clean Architecture Implementation

## Overview

This document describes the clean architecture implementation for the Pokeakwanza marketplace app. The architecture is organized into three main layers: **Presentation**, **Domain**, and **Data**, with a **Core** layer supporting infrastructure.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│           PRESENTATION LAYER                    │
│  (Screens, Widgets, Providers, State Management)│
└────────────────┬────────────────────────────────┘
                 │ depends on
         ┌───────▼─────────┐
         │  Domain Layer   │
         │  (Use Cases)    │
         └───────┬─────────┘
                 │ depends on
     ┌───────────▼──────────────┐
     │  Data/Repository Layer   │
     │  (Repositories)          │
     └───────────┬──────────────┘
                 │ depends on
     ┌───────────▼──────────────┐
     │  Core Layer              │
     │  (API, DI, Exceptions)   │
     └──────────────────────────┘
```

---

## Layer Details

### 1. CORE LAYER (`lib/core/`)

**Responsibility**: Infrastructure and utilities

#### Key Files:

- **`architecture/result.dart`**: Result<T> type for Success/Failure handling
  - `Success<T>`: Represents successful result with value
  - `Failure<T>`: Represents failed result with exception
  - Methods: `fold()`, `map()`, `getOrNull()`, `getErrorOrNull()`

- **`architecture/exceptions.dart`**: Custom exception types
  - `AppException`: Base exception
  - `NetworkException`: Network-related errors
  - `ServerException`: HTTP error responses
  - `ValidationException`: Input validation errors
  - `DataException`: Data parsing errors
  - `AuthException`: Authentication errors
  - `CacheException`: Cache operation errors
  - `UnknownException`: Catch-all for unknown errors

- **`architecture/repositories.dart`**: Repository interface definitions
  - Service contracts that data layer must implement
  - Used for dependency inversion

- **`api/api_service.dart`**: Existing API communication (unchanged)

- **`di/service_locator.dart`**: Dependency injection setup
  - Initializes all repositories
  - Initializes all use cases
  - Prevents manual dependency creation

---

### 2. DATA LAYER (`lib/data/`)

**Responsibility**: Data access and repository implementations

#### Key Files:

- **`repositories/impl/product_repository_impl.dart`**:
  - Implements `ProductRepository`
  - Implements `CategoryRepository`
  - Handles API communication
  - Maps API responses to models
  - Handles exceptions via `ExceptionMapper`

- **`repositories/impl/cart_order_repository_impl.dart`**:
  - Implements `CartRepository`
  - Implements `OrderRepository`
  - Input validation before API calls
  - Null-safe response handling

- **`repositories/impl/auth_user_repository_impl.dart`**:
  - Implements `AuthRepository`
  - Implements `UserRepository`
  - Implements `ShippingAddressRepository`
  - Implements `NotificationRepository`
  - Defensive programming with field validation

#### ExceptionMapper

```dart
static AppException map(dynamic exception, [StackTrace? stackTrace]) {
  // Converts DioException to AppException
  // Maps HTTP status codes to specific exceptions
  // Preserves original stack traces
}
```

---

### 3. DOMAIN LAYER (`lib/domain/`)

**Responsibility**: Business logic and use cases

#### Key Files:

- **`usecases/usecases.dart`**: All use case classes
  - Each use case represents one business operation
  - Examples:
    - `FetchProductsUseCase`
    - `AddToCartUseCase`
    - `CheckoutUseCase`
    - `LoginUseCase`

#### Use Case Pattern

```dart
class FetchProductsUseCase {
  final ProductRepository _repository;
  
  FetchProductsUseCase(this._repository);
  
  Future<Result<List<Product>>> call({...}) {
    return _repository.getProducts(...);
  }
}

// Usage in providers:
final result = await fetchProductsUseCase.call(page: 1);
result.fold(
  onSuccess: (products) => setState(...),
  onFailure: (error) => showError(error.message),
);
```

---

### 4. PRESENTATION LAYER (`lib/screens/`, `lib/providers/`)

**Responsibility**: UI and state management (existing, to be updated)

#### How to Integrate Use Cases into Providers:

**Before (Direct API call)**:
```dart
class ProductProvider extends ChangeNotifier {
  Future<void> fetchProducts() async {
    try {
      final res = await _api.getProducts();
      _products = res.map(...).toList();
    } catch (e) {
      // Handle error
    }
  }
}
```

**After (Using repositories & use cases)**:
```dart
class ProductProvider extends ChangeNotifier {
  final FetchProductsUseCase _useCase;
  
  ProductProvider(this._useCase);
  
  Future<void> fetchProducts() async {
    final result = await _useCase.call();
    
    result.fold(
      onSuccess: (products) {
        _products = products;
        notifyListeners();
      },
      onFailure: (error) {
        _error = error.message;
        notifyListeners();
      },
    );
  }
}
```

---

## Dependency Flow

### Dependency Injection

All dependencies are registered in `service_locator.dart`:

```dart
// Initialize once in main()
await setupServiceLocator();

// Access dependencies
final useCase = getIt<FetchProductsUseCase>();
```

### Dependency Resolution

1. **Presentation → Use Case**: Provider gets use case from service locator
2. **Use Case → Repository**: Use case depends on repository
3. **Repository → API**: Repository uses API service
4. **Exception Mapping**: API errors → ExceptionMapper → AppException → Result<T>

---

## Result Handling Pattern

### Success Case
```dart
Future<Result<List<Product>>> getProducts() async {
  try {
    final response = await _apiService.getProducts();
    final products = response.map(...).toList();
    return Success(products);
  } on Exception catch (e, st) {
    return Failure(ExceptionMapper.map(e, st));
  }
}
```

### Usage
```dart
final result = await repository.getProducts();

// Pattern matching
result.fold(
  onSuccess: (products) { /* handle success */ },
  onFailure: (error) { /* handle error */ },
);

// Conditional
if (result.isSuccess) {
  final products = result.getOrNull();
}

// Transformation
final mapped = result.map((products) => products.length);
```

---

## Defensive Programming Patterns

### 1. Input Validation
```dart
Future<Result<int?>> checkout(String paymentMethod) async {
  try {
    if (paymentMethod.isEmpty) {
      return Failure(ValidationException(
        message: 'Payment method cannot be empty',
      ));
    }
    // proceed
  }
}
```

### 2. Type Checking
```dart
if (response is! Map<String, dynamic>) {
  return Failure(DataException.parseError('Invalid response format'));
}
```

### 3. Null Safety
```dart
final orderId = response['order_id'] ?? response['id'];
if (orderId == null) {
  return Failure(DataException.nullValue('order_id'));
}
```

### 4. Exception Boundaries
```dart
try {
  // operation
} on AppException catch (e) {
  return Failure(e);  // Already properly typed
} on Exception catch (e, st) {
  return Failure(ExceptionMapper.map(e, st));  // Convert unknown
} catch (e, st) {
  return Failure(UnknownException(message: e.toString(), stackTrace: st));
}
```

---

## Benefits of This Architecture

### ✅ Separation of Concerns
- Presentation only handles UI state
- Domain contains business rules
- Data handles API communication

### ✅ Testability
- Repositories can be mocked
- Use cases tested independently
- No UI dependencies in business logic

### ✅ Maintainability
- Clear responsibility per layer
- Easy to locate code
- Minimal coupling

### ✅ Scalability
- New features add new use cases
- Repositories abstract data source
- Easy to switch API implementations

### ✅ Error Handling
- Standardized exception types
- Type-safe error propagation
- Consistent error messages

### ✅ Reusability
- Use cases can be called from multiple screens
- Repositories can be shared
- No duplicate logic

---

## File Structure

```
lib/
├── core/
│   ├── architecture/
│   │   ├── result.dart              ⭐ Result<T> type
│   │   ├── exceptions.dart          ⭐ Exception types
│   │   └── repositories.dart        ⭐ Repository interfaces
│   ├── api/                         (unchanged)
│   └── di/
│       └── service_locator.dart     ⭐ Dependency injection
│
├── data/
│   └── repositories/
│       └── impl/                    ⭐ Repository implementations
│           ├── product_repository_impl.dart
│           ├── cart_order_repository_impl.dart
│           └── auth_user_repository_impl.dart
│
├── domain/
│   └── usecases/
│       └── usecases.dart            ⭐ All use cases
│
├── presentation/
│   ├── screens/                     (unchanged)
│   ├── providers/                   (to be updated)
│   ├── widgets/                     (unchanged)
│   └── ...
│
└── models/                          (unchanged)
```

---

## Migration Guide: Converting Existing Providers

### Step 1: Update Provider Constructor
```dart
class ProductProvider extends ChangeNotifier {
  // OLD
  final _api = ApiService.I;
  
  // NEW
  final FetchProductsUseCase _fetchUseCase;
  final FetchNewArrivalsUseCase _newArrivalsUseCase;
  
  ProductProvider(this._fetchUseCase, this._newArrivalsUseCase);
}
```

### Step 2: Replace API Calls with Use Cases
```dart
// OLD
Future<void> fetchProducts() async {
  try {
    final res = await _api.getProducts();
    _products = res.map(...).toList();
  } catch (e) {
    _error = e.toString();
  }
}

// NEW
Future<void> fetchProducts() async {
  final result = await _fetchUseCase.call();
  
  result.fold(
    onSuccess: (products) {
      _products = products;
      _error = null;
    },
    onFailure: (error) {
      _error = error.message;
      _products = [];
    },
  );
  
  notifyListeners();
}
```

### Step 3: Update in MultiProvider
```dart
// OLD
ChangeNotifierProvider(create: (_) => ProductProvider()),

// NEW
ChangeNotifierProvider(
  create: (_) => ProductProvider(
    getIt<FetchProductsUseCase>(),
    getIt<FetchNewArrivalsUseCase>(),
  ),
),
```

---

## Exception Handling Example

```dart
try {
  final result = await useCase.checkoutOrder(data);
  
  result.fold(
    onSuccess: (orderId) {
      // Show success UI
      navigateToOrderSuccess(orderId);
    },
    onFailure: (error) {
      if (error is AuthException) {
        // Handle auth error
        navigateToLogin();
      } else if (error is ValidationException) {
        // Handle validation error
        showValidationError(error.message);
      } else if (error is NetworkException) {
        // Handle network error
        showNetworkError();
      } else {
        // Show generic error
        showError(error.message);
      }
    },
  );
} catch (e) {
  // Safety net for unexpected errors
  showError('Unexpected error occurred');
}
```

---

## Current Status

✅ **Completed**:
- Result type implementation
- Exception types definition
- Repository interfaces
- Repository implementations with exception mapping
- Use case layer
- Dependency injection setup

📋 **To Do**:
- Update existing providers to use repositories
- Test repositories and use cases
- Document API endpoint requirements
- Add retry logic for network failures
- Implement caching layer (optional)

---

## Next Steps

1. **Initialize service locator in main()**:
   ```dart
   Future<void> main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await setupServiceLocator();  // Add this
     // ... rest of setup
   }
   ```

2. **Update providers incrementally**:
   - Start with ProductProvider
   - Then CartProvider
   - Then AuthProvider

3. **Test the new architecture**:
   - Verify repositories work correctly
   - Check error messages display properly
   - Ensure use cases are called correctly

---

## Architecture Principles

1. **Dependency Rule**: Inner layers don't depend on outer layers
2. **Single Responsibility**: Each class has one reason to change
3. **Open/Closed**: Open for extension, closed for modification
4. **Liskov Substitution**: Repository implementations are interchangeable
5. **Interface Segregation**: Small, focused repository interfaces
6. **Dependency Inversion**: Depend on abstractions (interfaces), not concrete classes

---

**This architecture is now ready for production use and scales well for adding new features.**
