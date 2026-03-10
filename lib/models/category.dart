import 'package:stynext/core/config.dart';

class Category {
  final int id;
  final String name;
  final String? image;
  final String? slug;

  Category({
    required this.id,
    required this.name,
    this.image,
    this.slug,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final dynamic rawId = json['id'];
    final int id =
        rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    final String name =
        (json['name'] ?? json['title'] ?? 'Unknown Category').toString();

    String? rawImgCandidate;
    // Common flat keys
    rawImgCandidate = (json['image_url'] ??
            json['image'] ??
            json['thumbnail'] ??
            json['icon_url'] ??
            json['icon'] ??
            json['photo'] ??
            json['picture'] ??
            json['cover'] ??
            json['banner'] ??
            json['img'] ??
            json['image_path'])
        ?.toString();
    // Nested image objects (e.g., { image: { url: '...' } })
    if ((rawImgCandidate == null || rawImgCandidate.isEmpty) &&
        json['image'] is Map<String, dynamic>) {
      final img = Map<String, dynamic>.from(json['image'] as Map);
      rawImgCandidate = (img['url'] ??
              img['src'] ??
              img['path'] ??
              img['original'] ??
              img['full'] ??
              img['thumbnail'] ??
              img['small'] ??
              img['medium'])
          ?.toString();
    }
    // Fallback: storage_path / storage_url keys
    if ((rawImgCandidate == null || rawImgCandidate.isEmpty)) {
      rawImgCandidate =
          (json['storage_url'] ?? json['storage_path'])?.toString();
    }
    final String? fullImg = rawImgCandidate == null || rawImgCandidate.isEmpty
        ? null
        : AppConfig.normalizeImageUrl(rawImgCandidate);

    return Category(
      id: id,
      name: name,
      image: fullImg,
      slug: json['slug']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'slug': slug,
    };
  }
}
