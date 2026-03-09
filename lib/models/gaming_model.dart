import 'package:stynext/models/product.dart';

class GamingModel {
  final List<Product> products;
  final bool isLoading;

  GamingModel({this.products = const [], this.isLoading = false});
}
