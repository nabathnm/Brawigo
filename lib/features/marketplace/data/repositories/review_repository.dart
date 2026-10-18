import 'package:brawigo/features/marketplace/presentation/pages/models/seller_review_model.dart'
    show SellerReviewModel;
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewRepository {
  ReviewRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Buyer may submit one review for an order that belongs to them and is completed.
  Future<void> submitReview({
    required String orderId,
    required int rating,
    required String comment,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const ReviewRepositoryException(
        'Silakan login untuk memberikan ulasan.',
      );
    }
    if (rating < 1 || rating > 5) {
      throw const ReviewRepositoryException('Rating harus antara 1 sampai 5.');
    }

    final normalizedComment = comment.trim();
    if (normalizedComment.isEmpty) {
      throw const ReviewRepositoryException(
        'Komentar ulasan tidak boleh kosong.',
      );
    }

    final order = await _client
        .from('orders')
        .select('id, buyer_id, product_id, order_status')
        .eq('id', orderId)
        .maybeSingle();

    if (order == null) {
      throw const ReviewRepositoryException('Pesanan tidak ditemukan.');
    }
    if (order['buyer_id']?.toString() != user.id) {
      throw const ReviewRepositoryException(
        'Kamu hanya dapat mengulas pesanan milikmu.',
      );
    }
    if (order['order_status']?.toString().toLowerCase() != 'completed') {
      throw const ReviewRepositoryException(
        'Ulasan hanya dapat diberikan setelah pesanan selesai.',
      );
    }

    final existingReview = await _client
        .from('reviews')
        .select('id')
        .eq('order_id', orderId)
        .maybeSingle();
    if (existingReview != null) {
      throw const ReviewRepositoryException('Pesanan ini sudah pernah diulas.');
    }

    await _client.from('reviews').insert({
      'order_id': orderId,
      'product_id': order['product_id'],
      'reviewer_id': user.id,
      'rating': rating,
      'comment': normalizedComment,
    });
  }

  /// Gets reviews written for completed purchases from this seller's store.
  /// This uses separate queries instead of relying on implicit PostgREST FK aliases.
  Future<List<SellerReviewModel>> getSellerReviews(String sellerId) async {
    final completedOrders = await _client
        .from('orders')
        .select('id, product_id')
        .eq('seller_id', sellerId)
        .eq('order_status', 'completed');

    final orderRows = List<Map<String, dynamic>>.from(completedOrders);
    if (orderRows.isEmpty) return const [];

    final orderIds = orderRows
        .map((row) => row['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (orderIds.isEmpty) return const [];

    final reviewResponse = await _client
        .from('reviews')
        .select(
          'id, order_id, product_id, reviewer_id, rating, comment, created_at',
        )
        .inFilter('order_id', orderIds)
        .order('created_at', ascending: false);

    final reviewRows = List<Map<String, dynamic>>.from(reviewResponse);
    if (reviewRows.isEmpty) return const [];

    final reviewerIds = reviewRows
        .map((row) => row['reviewer_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final productIds = reviewRows
        .map((row) => row['product_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final Map<String, Map<String, dynamic>> profilesById = {};
    if (reviewerIds.isNotEmpty) {
      final profileResponse = await _client
          .from('profiles')
          .select('id, full_name, username, profile_photo_url')
          .inFilter('id', reviewerIds);
      for (final row in List<Map<String, dynamic>>.from(profileResponse)) {
        profilesById[row['id'].toString()] = row;
      }
    }

    final Map<String, Map<String, dynamic>> productsById = {};
    if (productIds.isNotEmpty) {
      final productResponse = await _client
          .from('products')
          .select('*')
          .inFilter('id', productIds);
      for (final row in List<Map<String, dynamic>>.from(productResponse)) {
        productsById[row['id'].toString()] = row;
      }
    }

    return reviewRows.map((row) {
      final review = SellerReviewModel.fromJson(row);
      final profile = profilesById[review.reviewerId];
      final product = productsById[review.productId];
      final name = profile?['full_name']?.toString().trim();
      final username = profile?['username']?.toString().trim();
      final productName = product?['product_name'] ?? product?['name'];

      return review.copyWith(
        reviewerName: (name != null && name.isNotEmpty)
            ? name
            : ((username != null && username.isNotEmpty)
                  ? username
                  : 'Pembeli'),
        reviewerPhotoUrl: profile?['profile_photo_url']?.toString(),
        productName: productName?.toString(),
      );
    }).toList();
  }
}

class ReviewRepositoryException implements Exception {
  const ReviewRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}
