import 'package:stynext/models/product.dart';

class MyAdsModel {
  final List<Product> ads;
  final bool isLoading;

  MyAdsModel({this.ads = const [], this.isLoading = false});
}
