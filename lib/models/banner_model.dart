import 'package:stynext/core/config.dart';

class BannerModel {
  final int id;
  final String image;
  final String title;
  final String subtitle;
  final String buttonText;
  final String position;

  BannerModel({
    this.id = 0,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    this.position = 'home',
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    final imgCandidate =
        (json['image_url'] ?? json['image'] ?? json['thumbnail'] ?? '')
            .toString();
    final fullImg = AppConfig.normalizeImageUrl(imgCandidate);

    return BannerModel(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      image: fullImg,
      title: (json['title'] ?? json['name'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      buttonText: json['button_text']?.toString() ?? 'Shop Now',
      position: (json['position']?.toString() ?? 'home'),
    );
  }
}
