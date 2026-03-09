import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Hive.openBox('products');
    await Hive.openBox('categories');
    await Hive.openBox('cart');
    await Hive.openBox('wishlist');
    _initialized = true;
  }

  static Future<void> putProducts(String key, List<Map<String, dynamic>> items) async {
    final box = Hive.box('products');
    await box.put(key, items);
  }

  static List<Map<String, dynamic>> getProducts(String key) {
    final box = Hive.box('products');
    final data = box.get(key);
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static Future<void> putCategories(List<Map<String, dynamic>> items) async {
    final box = Hive.box('categories');
    await box.put('all', items);
  }

  static List<Map<String, dynamic>> getCategories() {
    final box = Hive.box('categories');
    final data = box.get('all');
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static Future<void> putWishlistIds(List<int> ids) async {
    final box = Hive.box('wishlist');
    await box.put('ids', ids);
  }

  static List<int> getWishlistIds() {
    final box = Hive.box('wishlist');
    final data = box.get('ids');
    if (data is List) {
      return data.whereType<int>().toList();
    }
    return [];
  }
}
