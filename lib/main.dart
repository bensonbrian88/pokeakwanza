import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/network_service.dart';
import 'core/di/service_locator.dart';
import 'services/fcm_service.dart';
import 'features/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/firebase_otp_screen.dart';
import 'screens/home/main_screen.dart';
import 'screens/home/product_details_screen.dart';
import 'screens/home/cart_screen.dart';
import 'screens/home/category_products_screen.dart';
import 'screens/orders/order_success_screen.dart';
import 'screens/orders/order_history_screen.dart';
import 'screens/orders/order_detail_screen.dart';
import 'screens/payments/payment_screen.dart';
import 'screens/home/scan_screen.dart';
import 'screens/home/notifications_screen.dart';

// profile related screens
import 'screens/profile/shipping_address_screen.dart';
import 'screens/profile/payment_methods_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/profile/help_center_screen.dart';
import 'screens/profile/chat_list_screen.dart';
import 'screens/profile/chat_screen.dart';

// profile-related screens/providers
import 'package:stynext/core/navigation_service.dart';

// checkout screen
import 'features/cart/checkout_screen.dart';

/// Top-level function to handle background messages
/// Called by Firebase when app receives notification in background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Background message received: ${message.messageId}');
  // Firebase handles notification display automatically in background
  // Custom handling can be added here if needed
}

Future<Widget> getStartScreen() async {
  return const SplashScreen();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service locator (dependency injection)
  await setupServiceLocator();

  // Initialize network service
  await NetworkService().initialize();

  try {
    await Firebase.initializeApp();

    // Setup FCM background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize FCM service
    await FCMService().initialize();

    fb_auth.FirebaseAuth.instance
        .authStateChanges()
        .listen((fb_auth.User? user) {
      if (user != null) {
        // User logged in
      }
    });
  } catch (_) {
    // Safe fallback if Firebase not fully configured yet
  }
  final start = await getStartScreen();
  runApp(ProviderScope(child: PokeaKwanzaApp(start)));
}

class PokeaKwanzaApp extends StatelessWidget {
  final Widget startScreen;
  const PokeaKwanzaApp(this.startScreen, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Pokeakwanza',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: startScreen,
      onGenerateRoute: (RouteSettings settings) {
        Widget page;
        switch (settings.name) {
          case '/splash':
            page = const SplashScreen();
            break;
          case '/onboarding':
            page = const OnboardingScreen();
            break;
          case '/login':
            page = const LoginScreen();
            break;
          case '/register':
            page = const RegisterScreen();
            break;
          case '/otp':
            page = const OtpScreen();
            break;
          case '/otp_sms':
            final args = settings.arguments as Map<String, dynamic>?;
            final vid = args?['verificationId'] as String?;
            page = vid == null
                ? const Scaffold(
                    body: Center(child: Text('Missing verificationId')))
                : FirebaseOtpScreen(verificationId: vid);
            break;
          case '/home':
            page = const MainScreen();
            break;
          case '/product_details':
            page = const ProductDetailsScreen();
            break;
          case '/category_products':
            page = const CategoryProductsScreen();
            break;
          case '/cart':
            page = const CartScreen();
            break;
          case '/checkout':
            page = const CheckoutScreen();
            break;
          case '/scan':
            page = const ScanScreen();
            break;
          case '/notifications':
            page = const NotificationsScreen();
            break;
          case '/order_success':
            page = const OrderSuccessScreen();
            break;
          case '/orders':
            page = const OrderHistoryScreen();
            break;
          case '/order_detail':
            page = const OrderDetailScreen();
            break;
          case '/payment':
            page = const PaymentScreen();
            break;
          case '/shipping_addresses':
            page = const ShippingAddressScreen();
            break;
          case '/payment_methods':
            page = const PaymentMethodsScreen();
            break;
          case '/settings':
            page = const SettingsScreen();
            break;
          case '/help_center':
            page = const HelpCenterScreen();
            break;
          case '/chats':
            page = const ChatListScreen();
            break;
          case '/chat':
            page = const ChatScreen();
            break;
          default:
            page = startScreen;
        }
        return PageRouteBuilder(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (context, anim, secAnim) => page,
          transitionsBuilder: (context, anim, secAnim, child) {
            final fade = CurvedAnimation(parent: anim, curve: Curves.easeInOut);
            final offset = Tween<Offset>(
                    begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: offset, child: child),
            );
          },
        );
      },
    );
  }
}
