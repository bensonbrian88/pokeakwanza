class ApiConstants {
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String user = '/user';
  static const String verifyOtp = '/verify-otp';
  static const String resendOtp = '/resend-otp';
  static const String phoneCodes = '/phone-codes';
  static const String firebaseLogin = '/firebase-login';

  static const String categories = '/categories';
  static const String products = '/products';
  static const String productsNewArrivals = '/products/new-arrivals';
  static const String productsByCategory = '/products/category';
  static const String orders = '/orders';
  static const String ordersConfirm = '/orders/confirm';
  static const String orderTrack = '/orders/{order}/track';
  static const String orderLocation = '/orders/{order}/location';
  static const String orderConfirmDelivery = '/orders/{order}/confirm-delivery';
  static const String banners = '/banners';
  static const String notifications = '/notifications';
  static const String notificationsRead = '/notifications/read';
  static const String settings = '/settings';
  static const String settingsPublic = '/settings/public';
  static const String cart = '/cart';
  static const String cartAdd = '/cart/add';
  static const String cartSummary = '/cart/summary';
  static const String checkoutPreview = '/checkout/preview';
  static const String checkout = '/checkout';
  static const String saveDeviceToken = '/save-device-token';
  static const String usersFcmToken = '/users/fcm-token';

  // Profile-related endpoints
  static const String shippingAddresses = '/user/shipping-address';
  static const String paymentMethods = '/user/payment-methods';
  static const String updateProfile = '/user/update-profile';
  static const String helpCenter = '/help-center';
  static const String chats = '/chats';
}
