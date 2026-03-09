import 'package:get_it/get_it.dart';
import 'package:stynext/core/api/api_service.dart';
import 'package:stynext/core/architecture/repositories.dart';
import 'package:stynext/data/repositories/impl/product_repository_impl.dart';
import 'package:stynext/data/repositories/impl/cart_order_repository_impl.dart';
import 'package:stynext/data/repositories/impl/auth_user_repository_impl.dart';
import 'package:stynext/domain/usecases/usecases.dart';

/// Service Locator for dependency injection
/// This centralizes all dependency management
final getIt = GetIt.instance;

/// Initialize all dependencies
Future<void> setupServiceLocator() async {
  // ============== API & External ==============
  // API Service is a singleton
  getIt.registerSingleton<ApiService>(ApiService.I);

  // ============== Repositories ==============
  // Product Repository
  getIt.registerSingleton<ProductRepository>(
    ProductRepositoryImpl(getIt<ApiService>()),
  );

  // Category Repository
  getIt.registerSingleton<CategoryRepository>(
    CategoryRepositoryImpl(getIt<ApiService>()),
  );

  // Cart Repository
  getIt.registerSingleton<CartRepository>(
    CartRepositoryImpl(getIt<ApiService>()),
  );

  // Order Repository
  getIt.registerSingleton<OrderRepository>(
    OrderRepositoryImpl(getIt<ApiService>()),
  );

  // Auth Repository
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(getIt<ApiService>()),
  );

  // User Repository
  getIt.registerSingleton<UserRepository>(
    UserRepositoryImpl(getIt<ApiService>()),
  );

  // Shipping Address Repository
  getIt.registerSingleton<ShippingAddressRepository>(
    ShippingAddressRepositoryImpl(getIt<ApiService>()),
  );

  // Notification Repository
  getIt.registerSingleton<NotificationRepository>(
    NotificationRepositoryImpl(getIt<ApiService>()),
  );

  // ============== Use Cases ==============
  // Product Use Cases
  getIt.registerSingleton<FetchProductsUseCase>(
    FetchProductsUseCase(getIt<ProductRepository>()),
  );

  getIt.registerSingleton<FetchNewArrivalsUseCase>(
    FetchNewArrivalsUseCase(getIt<ProductRepository>()),
  );

  getIt.registerSingleton<FetchProductDetailUseCase>(
    FetchProductDetailUseCase(getIt<ProductRepository>()),
  );

  getIt.registerSingleton<FetchProductsByCategoryUseCase>(
    FetchProductsByCategoryUseCase(getIt<ProductRepository>()),
  );

  // Category Use Cases
  getIt.registerSingleton<FetchCategoriesUseCase>(
    FetchCategoriesUseCase(getIt<CategoryRepository>()),
  );

  // Cart Use Cases
  getIt.registerSingleton<FetchCartUseCase>(
    FetchCartUseCase(getIt<CartRepository>()),
  );

  getIt.registerSingleton<ClearCartUseCase>(
    ClearCartUseCase(getIt<CartRepository>()),
  );

  getIt.registerSingleton<AddToCartUseCase>(
    AddToCartUseCase(getIt<CartRepository>()),
  );

  getIt.registerSingleton<UpdateCartQuantityUseCase>(
    UpdateCartQuantityUseCase(getIt<CartRepository>()),
  );

  getIt.registerSingleton<RemoveFromCartUseCase>(
    RemoveFromCartUseCase(getIt<CartRepository>()),
  );

  // Order Use Cases
  getIt.registerSingleton<FetchOrdersUseCase>(
    FetchOrdersUseCase(getIt<OrderRepository>()),
  );

  getIt.registerSingleton<FetchOrderDetailUseCase>(
    FetchOrderDetailUseCase(getIt<OrderRepository>()),
  );

  getIt.registerSingleton<CheckoutUseCase>(
    CheckoutUseCase(getIt<OrderRepository>()),
  );

  getIt.registerSingleton<CreateOrderUseCase>(
    CreateOrderUseCase(getIt<OrderRepository>()),
  );

  // Auth Use Cases
  getIt.registerSingleton<LoginUseCase>(
    LoginUseCase(getIt<AuthRepository>()),
  );

  getIt.registerSingleton<RegisterUseCase>(
    RegisterUseCase(getIt<AuthRepository>()),
  );

  getIt.registerSingleton<LogoutUseCase>(
    LogoutUseCase(getIt<AuthRepository>()),
  );
  // User Use Cases
  getIt.registerSingleton<FetchUserUseCase>(
    FetchUserUseCase(getIt<UserRepository>()),
  );

  getIt.registerSingleton<UpdateUserProfileUseCase>(
    UpdateUserProfileUseCase(getIt<UserRepository>()),
  );
  // Address Use Cases
  getIt.registerSingleton<FetchAddressesUseCase>(
    FetchAddressesUseCase(getIt<ShippingAddressRepository>()),
  );

  getIt.registerSingleton<AddAddressUseCase>(
    AddAddressUseCase(getIt<ShippingAddressRepository>()),
  );

  // Notification Use Cases
  getIt.registerSingleton<FetchNotificationsUseCase>(
    FetchNotificationsUseCase(getIt<NotificationRepository>()),
  );
}
