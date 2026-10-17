import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailRepository {
  OrderDetailRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<Map<String, dynamic>> fetchOrder(String orderId) async {
    final data = await _client
        .from('orders')
        .select()
        .eq('id', orderId)
        .single();
    return Map<String, dynamic>.from(data);
  }

  Future<void> sendChatUpdate({
    required Map<String, dynamic> order,
    required String message,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final buyerId = order['buyer_id']?.toString() ?? '';
    final sellerId = order['seller_id']?.toString() ?? '';
    if (buyerId.isEmpty || sellerId.isEmpty) return;

    try {
      final result = await _client
          .from('conversations')
          .select('id')
          .eq('buyer_id', buyerId)
          .eq('seller_id', sellerId)
          .limit(1);

      final conversations = result as List;
      if (conversations.isEmpty) return;

      final conversationId = conversations.first['id'];
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': user.id,
        'message': message,
        'is_read': false,
      });

      await _client
          .from('conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);
    } catch (_) {
      // Chat notification is best-effort; order status update remains primary.
    }
  }
}
