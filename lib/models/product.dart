import 'package:stynext/core/config.dart';

class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? image;
  final int? categoryId;
  final int? stock;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.image,
    this.categoryId,
    this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final dynamic rawId = json['id'];
    final int id =
        rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    final String name =
        (json['name'] ?? json['title'] ?? 'Unknown Product').toString();

    final dynamic rawPrice = json['price'] ?? json['discount_price'];
    final double price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '0.0') ?? 0.0;

    final String? rawImgCandidate = (json['image_url'] ??
            json['image'] ??
            json['thumbnail'] ??
            json['photo'])
        ?.toString();
    final String? fullImg = rawImgCandidate == null || rawImgCandidate.isEmpty
        ? null
        : AppConfig.normalizeImageUrl(rawImgCandidate);

    return Product(
      id: id,
      name: name,
      description: json['description']?.toString(),
      price: price,
      image: fullImg,
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse(json['category_id']?.toString() ?? ''),
      stock: json['stock'] is int
          ? json['stock']
          : int.tryParse(json['stock']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'category_id': categoryId,
      'stock': stock,
    };
  }
}
