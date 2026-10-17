import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _order;
  String? _errorMessage;
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    try {
      final data = await _supabase
          .from('orders')
          .select()
          .eq('id', widget.orderId)
          .single();

      if (mounted) {
        setState(() {
          _order = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendChatUpdate(String message) async {
    final order = _order;
    if (order == null) return;
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    final buyerId = order['buyer_id']?.toString() ?? '';
    final sellerId = order['seller_id']?.toString() ?? '';
    if (buyerId.isEmpty || sellerId.isEmpty) return;

    try {
      final existingConv = await _supabase
          .from('conversations')
          .select('id')
          .eq('buyer_id', buyerId)
          .eq('seller_id', sellerId)
          .limit(1);

      String? convId;
      final List convList = existingConv as List;
      if (convList.isNotEmpty) {
        convId = convList.first['id'];
      }

      if (convId != null) {
        await _supabase.from('messages').insert({
          'conversation_id': convId,
          'sender_id': currentUser.id,
          'message': message,
          'is_read': false,
        });

        await _supabase
            .from('conversations')
            .update({'updated_at': DateTime.now().toIso8601String()})
            .eq('id', convId);
      }
    } catch (_) {}
  }

  void _confirmCancelOrder() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini? Aksi ini tidak dapat diurungkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Kembali', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              context.read<OrderBloc>().add(UpdateOrderStatus(orderId: widget.orderId, status: 'cancelled'));
              final productName = _order?['product_name_snapshot'] ?? 'produk';
              await _sendChatUpdate("❌ Pesanan '$productName' telah dibatalkan.");
            },
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
  }

  void _showProofDialog(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String rawStatus) {
    final status = rawStatus.toLowerCase();
    if (status == 'confirmed') {
      return {
        'label': 'Dikonfirmasi / Diproses',
        'bg': const Color(0xFFE6EDF8),
        'text': const Color(0xFF2B5F9E),
        'icon': Icons.check_circle_outline_rounded,
      };
    } else if (status == 'completed') {
      return {
        'label': 'Pesanan Selesai',
        'bg': const Color(0xFFDCFCE7),
        'text': const Color(0xFF16A34A),
        'icon': Icons.task_alt_rounded,
      };
    } else if (status == 'cancelled') {
      return {
        'label': 'Pesanan Dibatalkan',
        'bg': const Color(0xFFFEE2E2),
        'text': const Color(0xFFDC2626),
        'icon': Icons.cancel_outlined,
      };
    } else {
      return {
        'label': 'Menunggu Konfirmasi',
        'bg': const Color(0xFFFEF3C7),
        'text': const Color(0xFFD97706),
        'icon': Icons.hourglass_top_rounded,
      };
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('EEEE, d MMMM yyyy - HH:mm', 'id_ID').format(dt) + ' WIB';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF15243C),
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15243C), fontSize: 18),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC8DAEF), Color(0xFFE6EDF8), Color(0xFFFAFAFA)],
            stops: [0.0, 0.2, 1.0],
          ),
        ),
        child: BlocConsumer<OrderBloc, OrderState>(
          listener: (context, state) {
            if (state is OrderSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message ?? 'Berhasil diperbarui'), backgroundColor: Colors.green),
              );
              _fetchOrderDetail();
            } else if (state is OrderError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            if (_isLoading || (state is OrderLoading && _order == null)) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF2B5F9E)));
            }

            if (_errorMessage != null || _order == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 56),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage ?? 'Pesanan tidak ditemukan.',
                        style: const TextStyle(color: Color(0xFF15243C), fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B5F9E)),
                        onPressed: _fetchOrderDetail,
                        child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              );
            }

            final order = _order!;
            final productName = order['product_name_snapshot'] ?? 'Produk Brawigo';
            final num totalAmount = (order['total_amount'] as num?) ?? (order['product_price_snapshot'] as num?) ?? 0;
            final paymentMethod = order['payment_method']?.toString() ?? 'COD';
            final rawStatus = (order['order_status'] ?? order['status'] ?? 'created').toString();
            final statusCfg = _getStatusConfig(rawStatus);
            final String? proofUrl = order['payment_proof_url']?.toString();
            final meetupLocation = order['meetup_location'] ?? '-';
            final meetupTime = order['meetup_time'] ?? '-';
            final quantity = order['quantity']?.toString() ?? '1';
            final notes = order['notes']?.toString();
            final createdAt = _formatDate(order['created_at']?.toString());
            final thumbnailUrl = order['thumbnail_url_snapshot'] as String?;

            final currentUserId = _supabase.auth.currentUser?.id;
            final isSeller = currentUserId == order['seller_id'];

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Status Card
                  _buildCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Status Pesanan', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              statusCfg['label'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: statusCfg['text'] as Color,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusCfg['bg'] as Color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(statusCfg['icon'] as IconData, color: statusCfg['text'] as Color, size: 22),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Product Information Card
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Produk',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF15243C)),
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                                  ? Image.network(
                                      thumbnailUrl,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                    )
                                  : _buildPlaceholder(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF15243C)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Jumlah: $quantity item',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currencyFormat.format(totalAmount),
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2B5F9E), fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Meetup / Delivery & Notes Info
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lokasi & Pengiriman',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF15243C)),
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(Icons.location_on_outlined, 'Lokasi / Alamat', meetupLocation),
                        if (meetupTime.isNotEmpty && meetupTime != '-') ...[
                          const SizedBox(height: 10),
                          _buildInfoRow(Icons.access_time_rounded, 'Waktu Bertemu', meetupTime),
                        ],
                        if (notes != null && notes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildInfoRow(Icons.notes_rounded, 'Catatan Pembeli', notes),
                        ],
                        const SizedBox(height: 10),
                        _buildInfoRow(Icons.calendar_today_rounded, 'Waktu Transaksi', createdAt),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Payment Info & Proof of Payment
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Metode Pembayaran',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF15243C)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                paymentMethod,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2B5F9E)),
                              ),
                            ),
                          ],
                        ),
                        if (proofUrl != null && proofUrl.isNotEmpty) ...[
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          const Text(
                            'Bukti Pembayaran (Screenshot Transfer/QRIS):',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showProofDialog(proofUrl),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    proofUrl,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 100,
                                      color: Colors.grey.shade100,
                                      child: const Center(child: Text("Gagal memuat gambar bukti")),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                      SizedBox(width: 4),
                                      Text('Klik untuk perbesar', style: TextStyle(color: Colors.white, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 6),
                          const Text(
                            'Pembayaran tunai saat transaksi langsung (COD) atau belum mengunggah bukti.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. Action Buttons (Seller or Buyer)
                  if (isSeller) ...[
                    // Seller Actions
                    if (rawStatus.toLowerCase() == 'created' || rawStatus.toLowerCase() == 'pending') ...[
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2B5F9E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Konfirmasi & Terima Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          onPressed: () async {
                            context.read<OrderBloc>().add(
                              UpdateOrderStatus(orderId: widget.orderId, status: 'confirmed'),
                            );
                            await _sendChatUpdate("✅ Penjual telah mengonfirmasi pesanan '$productName'!");
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (rawStatus.toLowerCase() == 'confirmed') ...[
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.task_alt_rounded),
                          label: const Text('Selesaikan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          onPressed: () async {
                            context.read<OrderBloc>().add(
                              UpdateOrderStatus(orderId: widget.orderId, status: 'completed'),
                            );
                            await _sendChatUpdate("🎉 Pesanan '$productName' telah selesai!");
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (rawStatus.toLowerCase() != 'completed' && rawStatus.toLowerCase() != 'cancelled') ...[
                      SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Batalkan Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _confirmCancelOrder,
                        ),
                      ),
                    ],
                  ] else ...[
                    // Buyer Actions
                    if (rawStatus.toLowerCase() == 'confirmed') ...[
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text('Konfirmasi Barang Diterima (Selesai)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          onPressed: () async {
                            context.read<OrderBloc>().add(
                              UpdateOrderStatus(orderId: widget.orderId, status: 'completed'),
                            );
                            await _sendChatUpdate("📦 Pembeli telah mengonfirmasi bahwa barang '$productName' sudah diterima.");
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2B5F9E)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF15243C)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFFE2E8F0),
      child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF94A3B8), size: 28),
    );
  }
}

