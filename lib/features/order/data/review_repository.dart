import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewRepository {
  ReviewRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Silakan login terlebih dahulu.');
    }
    return user.id;
  }

  /// Mengambil pesanan dan memeriksa apakah sudah direview.
  Future<Map<String, dynamic>> getReviewData(String orderId) async {
    final userId = _userId;

    final order = await _client
        .from('orders')
        .select('id, buyer_id, product_id, product_name_snapshot, order_status')
        .eq('id', orderId)
        .maybeSingle();

    if (order == null) {
      throw Exception('Pesanan tidak ditemukan.');
    }

    if (order['buyer_id'] != userId) {
      throw Exception('Kamu tidak memiliki akses ke pesanan ini.');
    }

    final status = (order['order_status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    if (status != 'completed') {
      throw Exception('Review hanya dapat diberikan untuk pesanan selesai.');
    }

    final existingReview = await _client
        .from('reviews')
        .select(
          'id, order_id, product_id, reviewer_id, rating, comment, created_at',
        )
        .eq('order_id', orderId)
        .maybeSingle();

    return {'order': order, 'review': existingReview};
  }

  /// Menyimpan review baru.
  Future<void> submitReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) {
      throw Exception('Rating harus antara 1 sampai 5.');
    }

    final userId = _userId;
    final data = await getReviewData(orderId);

    final order = data['order'] as Map<String, dynamic>;
    final existingReview = data['review'] as Map<String, dynamic>?;

    if (existingReview != null) {
      throw Exception('Pesanan ini sudah memiliki review.');
    }

    final productId = order['product_id']?.toString();

    if (productId == null || productId.isEmpty) {
      throw Exception('Produk pada pesanan tidak ditemukan.');
    }

    await _client.from('reviews').insert({
      'order_id': orderId,
      'product_id': productId,
      'reviewer_id': userId,
      'rating': rating,
      'comment': (comment == null || comment.trim().isEmpty)
          ? null
          : comment.trim(),
    });
  }
}
