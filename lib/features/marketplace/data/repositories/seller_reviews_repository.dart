import 'package:supabase_flutter/supabase_flutter.dart';

class SellerReviewsRepository {
  SellerReviewsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Reviews from buyers whose order with this seller has been completed.
  Future<List<Map<String, dynamic>>> fetchSellerReviews(String sellerId) async {
    if (sellerId.isEmpty) return <Map<String, dynamic>>[];

    final response = await _client
        .from('reviews')
        .select(
          'id, order_id, product_id, reviewer_id, rating, comment, created_at, '
          'orders!inner(seller_id, order_status)',
        )
        .eq('orders.seller_id', sellerId)
        .eq('orders.order_status', 'completed')
        .order('created_at', ascending: false);

    final reviews = (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    if (reviews.isEmpty) return reviews;

    final reviewerIds = reviews
        .map((review) => review['reviewer_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final productIds = reviews
        .map((review) => review['product_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final profilesById = <String, Map<String, dynamic>>{};
    final productsById = <String, Map<String, dynamic>>{};

    if (reviewerIds.isNotEmpty) {
      final profileRows = await _client
          .from('profiles')
          .select('id, full_name, username, profile_photo_url')
          .inFilter('id', reviewerIds);
      for (final row in profileRows as List) {
        final profile = Map<String, dynamic>.from(row as Map);
        profilesById[profile['id'].toString()] = profile;
      }
    }

    if (productIds.isNotEmpty) {
      final productRows = await _client
          .from('products')
          .select('id, product_name, thumbnail_url')
          .inFilter('id', productIds);

      for (final row in productRows as List) {
        final product = Map<String, dynamic>.from(row as Map);
        productsById[product['id'].toString()] = product;
      }
    }

    return reviews.map((review) {
      final reviewerId = review['reviewer_id']?.toString() ?? '';
      final productId = review['product_id']?.toString() ?? '';
      return <String, dynamic>{
        ...review,
        'reviewer': profilesById[reviewerId],
        'product': productsById[productId],
      };
    }).toList();
  }
}
//  masih muncul pesan: gagal memuat ulasan toko: postgrestexception(message: column products.name does not exist, code 42703, detail: ,hint: null)
