import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'chat_room_page.dart';

class ChatListPage extends StatefulWidget {
  final bool isSeller;
  const ChatListPage({super.key, this.isSeller = false});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribeToChanges();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final query = _supabase
          .from('conversations')
          .select('id, buyer_id, seller_id, product_id, updated_at');

      final convResponse = widget.isSeller
          ? await query.eq('seller_id', currentUser.id).order('updated_at', ascending: false)
          : await query.eq('buyer_id', currentUser.id).order('updated_at', ascending: false);

      final List<Map<String, dynamic>> enrichedConvs = [];

      for (final conv in (convResponse as List)) {
        final otherId = conv['buyer_id'] == currentUser.id
            ? conv['seller_id']
            : conv['buyer_id'];

        final profileRes = await _supabase
            .from('profiles')
            .select('full_name, profile_photo_url')
            .eq('id', otherId)
            .maybeSingle();

        final lastMsgRes = await _supabase
            .from('messages')
            .select('message, created_at, sender_id')
            .eq('conversation_id', conv['id'])
            .order('created_at', ascending: false)
            .limit(1);

        final unreadRes = await _supabase
            .from('messages')
            .select('id')
            .eq('conversation_id', conv['id'])
            .eq('is_read', false)
            .neq('sender_id', currentUser.id);

        final lastMsg = (lastMsgRes as List).isNotEmpty ? lastMsgRes.first : null;
        final unreadCount = (unreadRes as List).length;

        enrichedConvs.add({
          'id': conv['id'],
          'other_user_id': otherId,
          'other_user_name': profileRes?['full_name'] ?? 'Pengguna',
          'other_user_photo': profileRes?['profile_photo_url'],
          'last_message': lastMsg?['message'] ?? 'Belum ada pesan',
          'last_message_time': lastMsg?['created_at'],
          'unread_count': unreadCount,
          'product_id': conv['product_id'],
        });
      }

      if (mounted) {
        setState(() {
          _conversations = enrichedConvs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToChanges() {
    _channel = _supabase
        .channel('chat_list_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (_) => _loadConversations(),
        )
        .subscribe();
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '';
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return DateFormat('HH:mm').format(dt);
      }
      return DateFormat('dd/MM').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'Chat',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF15243C),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari',
                    hintStyle: TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: Color(0xFFA0AEC0), size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _conversations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada percakapan',
                                style: TextStyle(color: Colors.grey, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadConversations,
                          child: ListView.separated(
                            itemCount: _conversations.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                            itemBuilder: (context, index) {
                              final conv = _conversations[index];
                              return _ConversationTile(
                                name: conv['other_user_name'],
                                photoUrl: conv['other_user_photo'],
                                lastMessage: conv['last_message'],
                                time: _formatTime(conv['last_message_time']),
                                unreadCount: conv['unread_count'],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatRoomPage(
                                        conversationId: conv['id'],
                                        otherUserName: conv['other_user_name'],
                                        otherUserId: conv['other_user_id'],
                                      ),
                                    ),
                                  ).then((_) => _loadConversations());
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.name,
    required this.photoUrl,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF4A7EBB),
        backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
            ? NetworkImage(photoUrl!)
            : null,
        child: (photoUrl == null || photoUrl!.isEmpty)
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              )
            : null,
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: Color(0xFF15243C),
        ),
      ),
      subtitle: Text(
        lastMessage,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: unreadCount > 0 ? const Color(0xFF2B5F9E) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2B5F9E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}
