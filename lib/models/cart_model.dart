import 'package:stynext/models/cart_item.dart';

class CartModel {
  final List<CartItem> items;
  final double totalAmount;

  CartModel({this.items = const [], this.totalAmount = 0.0});
}
