class Review {
  final int id;
  final int productId;
  final String author;
  final String comment;
  final int rating;
  final String createdAt;

  Review({
    required this.id,
    required this.productId,
    required this.author,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      productId: int.tryParse('${json['product_id'] ?? 0}') ?? 0,
      author: json['author']?.toString() ??
          json['user']?['name']?.toString() ??
          'Anonymous',
      comment: json['comment']?.toString() ?? json['content']?.toString() ?? '',
      rating: int.tryParse('${json['rating'] ?? 0}') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
