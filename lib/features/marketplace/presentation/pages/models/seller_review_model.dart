class SellerReviewModel {
  const SellerReviewModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.reviewerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.reviewerName,
    this.reviewerPhotoUrl,
    this.productName,
  });

  final String id;
  final String orderId;
  final String productId;
  final String reviewerId;
  final int rating;
  final String comment;
  final DateTime? createdAt;
  final String? reviewerName;
  final String? reviewerPhotoUrl;
  final String? productName;

  factory SellerReviewModel.fromJson(Map<String, dynamic> json) {
    return SellerReviewModel(
      id: (json['id'] ?? '').toString(),
      orderId: (json['order_id'] ?? '').toString(),
      productId: (json['product_id'] ?? '').toString(),
      reviewerId: (json['reviewer_id'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: (json['comment'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      reviewerName: json['reviewer_name']?.toString(),
      reviewerPhotoUrl: json['reviewer_photo_url']?.toString(),
      productName: json['product_name']?.toString(),
    );
  }

  SellerReviewModel copyWith({
    String? reviewerName,
    String? reviewerPhotoUrl,
    String? productName,
  }) {
    return SellerReviewModel(
      id: id,
      orderId: orderId,
      productId: productId,
      reviewerId: reviewerId,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerPhotoUrl: reviewerPhotoUrl ?? this.reviewerPhotoUrl,
      productName: productName ?? this.productName,
    );
  }
}
