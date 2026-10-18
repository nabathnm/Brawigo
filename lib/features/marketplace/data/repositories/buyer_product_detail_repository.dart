import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatConversationResult {
  const ChatConversationResult({
    required this.conversationId,
    required this.sellerName,
    required this.shouldSendMention,
  });

  final String conversationId;
  final String sellerName;
  final bool shouldSendMention;
}

class BuyerProductDetailRepository {
  BuyerProductDetailRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<String>> fetchProductImages(Map<String, dynamic> product) async {
    final productId = product['id']?.toString();
    if (productId == null || productId.isEmpty) {
      return _fallbackImage(product);
    }

    final response = await _client
        .from('product_images')
        .select('image_url')
        .eq('product_id', productId)
        .order('image_order', ascending: true);

    final images = (response as List)
        .map((item) => item['image_url']?.toString() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    return images.isNotEmpty ? images : _fallbackImage(product);
  }

  List<String> _fallbackImage(Map<String, dynamic> product) {
    // Pertahankan perilaku awal: fallback gallery menggunakan image_url.
    final image = product['image_url']?.toString();
    return image == null || image.isEmpty ? <String>[] : <String>[image];
  }

  Future<Map<String, dynamic>?> fetchSellerProfile(String sellerId) async {
    if (sellerId.isEmpty) return null;
    final result = await _client
        .from('profiles')
        .select('full_name, username, profile_photo_url, bio')
        .eq('id', sellerId)
        .maybeSingle();
    return result == null ? null : Map<String, dynamic>.from(result);
  }

  Future<void> saveToRecentlyViewed(String? productId) async {
    if (productId == null || productId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final viewed = prefs.getStringList('recently_viewed') ?? <String>[];
    viewed.remove(productId);
    viewed.add(productId);
    if (viewed.length > 10) viewed.removeAt(0);
    await prefs.setStringList('recently_viewed', viewed);
  }

  Future<ChatConversationResult> openOrCreateConversation({
    required String buyerId,
    required String sellerId,
    required String productId,
  }) async {
    final conversations = await _client
        .from('conversations')
        .select('id, product_id, buyer_id, seller_id')
        .or('buyer_id.eq.$buyerId,seller_id.eq.$buyerId')
        .order('updated_at', ascending: false);

    Map<String, dynamic>? existing;
    for (final row in conversations as List) {
      final conversation = Map<String, dynamic>.from(row as Map);
      final buyer = conversation['buyer_id']?.toString();
      final seller = conversation['seller_id']?.toString();
      if ((buyer == buyerId && seller == sellerId) ||
          (buyer == sellerId && seller == buyerId)) {
        existing = conversation;
        break;
      }
    }

    late String conversationId;
    var shouldSendMention = false;

    if (existing != null) {
      conversationId = existing['id'].toString();
      shouldSendMention = existing['product_id']?.toString() != productId;
      await _client
          .from('conversations')
          .update({
            'product_id': productId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conversationId);
    } else {
      try {
        final created = await _client
            .from('conversations')
            .insert({
              'buyer_id': buyerId,
              'seller_id': sellerId,
              'product_id': productId,
            })
            .select('id')
            .single();
        conversationId = created['id'].toString();
        shouldSendMention = true;
      } on PostgrestException catch (error) {
        if (error.code != '23505') rethrow;

        // Menangani race condition jika percakapan dibuat bersamaan.
        final rows = await _client
            .from('conversations')
            .select('id, product_id')
            .or('and(buyer_id.eq.$buyerId,seller_id.eq.$sellerId),and(buyer_id.eq.$sellerId,seller_id.eq.$buyerId)')
            .order('updated_at', ascending: false)
            .limit(1);

        if ((rows as List).isEmpty) rethrow;
        final row = Map<String, dynamic>.from(rows.first as Map);
        conversationId = row['id'].toString();
        shouldSendMention = true;
        await _client
            .from('conversations')
            .update({
              'product_id': productId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', conversationId);
      }
    }

    final profile = await _client
        .from('profiles')
        .select('full_name')
        .eq('id', sellerId)
        .maybeSingle();

    return ChatConversationResult(
      conversationId: conversationId,
      sellerName: profile?['full_name']?.toString() ?? 'Penjual',
      shouldSendMention: shouldSendMention,
    );
  }
}
