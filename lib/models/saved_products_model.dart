import 'package:stynext/models/product.dart';

class SavedProductsModel {
  final List<Product> products;
  final bool isLoading;

  SavedProductsModel({this.products = const [], this.isLoading = false});
}
