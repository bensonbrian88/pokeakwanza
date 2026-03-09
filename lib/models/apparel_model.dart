import 'package:stynext/models/product.dart';

class ApparelModel {
  final List<Product> products;
  final bool isLoading;

  ApparelModel({this.products = const [], this.isLoading = false});
}
