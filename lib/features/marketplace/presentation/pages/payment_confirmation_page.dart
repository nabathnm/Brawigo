import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class PaymentConfirmationPage extends StatefulWidget {
  final Map<String, dynamic> checkoutData;

  const PaymentConfirmationPage({super.key, required this.checkoutData});

  @override
  State<PaymentConfirmationPage> createState() => _PaymentConfirmationPageState();
}

class _PaymentConfirmationPageState extends State<PaymentConfirmationPage> {
  final _supabase = Supabase.instance.client;
  XFile? _proofImage;
  bool _isSubmitting = false;

  // Seller payment details
  String? _sellerQrisUrl;
  final String _sellerBankName = 'Bank BCA';
  final String _sellerAccountNumber = '8220192831';
  String _sellerAccountHolder = 'Brawigo Store';

  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchSellerPaymentInfo();
  }

  Future<void> _fetchSellerPaymentInfo() async {
    final product = widget.checkoutData['product'] as Map?;
    final sellerId = product?['seller_id']?.toString();
    if (sellerId == null || sellerId.isEmpty) return;

    try {
      final res = await _supabase
          .from('profiles')
          .select('full_name, phone_number, profile_photo_url')
          .eq('id', sellerId)
          .maybeSingle();

      if (res != null && mounted) {
        final name = res['full_name']?.toString();
        if (name != null && name.isNotEmpty) {
          setState(() {
            _sellerAccountHolder = name;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _pickProofImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      setState(() {
        _proofImage = image;
      });
    }
  }

  Future<void> _submitOrder() async {
    final paymentMethod = widget.checkoutData['payment_method'] as String?;
    if (paymentMethod != 'cash' && _proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap unggah screenshot bukti pembayaran terlebih dahulu.')),
      );
      return;
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final product = widget.checkoutData['product'] as Map;
      final sellerId = product['seller_id']?.toString() ?? '';
      final productId = product['id']?.toString() ?? '';
      final productName = product['name'] ?? product['product_name'] ?? 'Produk';
      final price = widget.checkoutData['price'] as double;
      final thumbnailUrl = product['image_url'] ?? product['thumbnail_url'] ?? '';

      String? uploadedProofUrl;

      // 1. Upload foto bukti pembayaran jika ada
      if (_proofImage != null) {
        final bytes = await _proofImage!.readAsBytes();
        final ext = _proofImage!.name.split('.').last.toLowerCase();
        final fileName = 'proofs/${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        await _supabase.storage.from('product_images').uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(contentType: 'image/$ext'),
            );
        uploadedProofUrl = _supabase.storage.from('product_images').getPublicUrl(fileName);
      }

      // 2. Insert ke tabel orders
      await _supabase.from('orders').insert({
        'buyer_id': currentUser.id,
        'seller_id': sellerId.isNotEmpty ? sellerId : currentUser.id,
        'product_id': productId.isNotEmpty ? productId : null,
        'product_name_snapshot': productName,
        'product_price_snapshot': price,
        'thumbnail_url_snapshot': thumbnailUrl,
        'quantity': 1,
        'total_amount': price,
        'payment_method': widget.checkoutData['payment_method_title'],
        'meetup_location': widget.checkoutData['meetup_location'] ?? widget.checkoutData['delivery_address'],
        'meetup_time': widget.checkoutData['meetup_time'],
        'notes': widget.checkoutData['notes'],
        'order_status': 'created',
        'payment_status': uploadedProofUrl != null ? 'paid' : 'pending',
      });

      // 3. Kirim pesan konfirmasi otomatis ke conversation chat
      if (sellerId.isNotEmpty && sellerId != currentUser.id) {
        try {
          final existingConv = await _supabase
              .from('conversations')
              .select('id')
              .eq('buyer_id', currentUser.id)
              .eq('seller_id', sellerId)
              .limit(1);

          String convId;
          final List convList = existingConv as List;
          if (convList.isNotEmpty) {
            convId = convList.first['id'];
          } else {
            final createdConv = await _supabase
                .from('conversations')
                .insert({
                  'buyer_id': currentUser.id,
                  'seller_id': sellerId,
                  'product_id': productId.isNotEmpty ? productId : null,
                })
                .select('id')
                .single();
            convId = createdConv['id'];
          }

          final orderNotice = "🧾 PESANAN BARU!\n"
              "Produk: $productName\n"
              "Total: ${_currencyFormat.format(price)}\n"
              "Metode Pembayaran: ${widget.checkoutData['payment_method_title']}\n"
              "Pengambilan: ${widget.checkoutData['pickup_method_title']}\n"
              "${uploadedProofUrl != null ? 'Bukti pembayaran telah diunggah.' : 'Menunggu pembayaran tunai saat COD.'}";

          await _supabase.from('messages').insert({
            'conversation_id': convId,
            'sender_id': currentUser.id,
            'message': orderNotice,
            'is_read': false,
          });

          await _supabase
              .from('conversations')
              .update({'updated_at': DateTime.now().toIso8601String()})
              .eq('id', convId);
        } catch (_) {}
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text("Pesanan Berhasil!"),
              ],
            ),
            content: const Text(
              "Pesanan kamu telah berhasil dibuat dan bukti pembayaran telah dikirimkan ke penjual.",
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B5F9E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.go('/home', extra: 2);
                },
                child: const Text("Lihat Riwayat Pesanan", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim pesanan: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethod = widget.checkoutData['payment_method'] as String? ?? 'qris';
    final price = widget.checkoutData['price'] as double? ?? 0.0;
    final formattedPrice = _currencyFormat.format(price);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Pembayaran & Bukti Transfer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF15243C),
        elevation: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Instruction Header ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF2B5F9E), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Lakukan pembayaran sebesar $formattedPrice ke rekening/QRIS toko penjual di bawah ini.",
                        style: const TextStyle(fontSize: 13, color: Color(0xFF15243C), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- QRIS / Transfer Bank Display ---
              if (paymentMethod == 'qris') ...[
                _buildQrisCard(formattedPrice),
              ] else if (paymentMethod == 'transfer') ...[
                _buildBankCard(),
              ] else ...[
                _buildCashCard(formattedPrice),
              ],
              const SizedBox(height: 24),

              // --- Upload Bukti Pembayaran Section ---
              const Text(
                "Upload Bukti Pembayaran",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15243C),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Unggah screenshot bukti transfer / pembayaran kamu.",
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickProofImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _proofImage != null ? const Color(0xFF2B5F9E) : const Color(0xFFCBD5E1),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _proofImage != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.network(
                                      _proofImage!.path,
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_proofImage!.path),
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _proofImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.cloud_upload_outlined, size: 48, color: Color(0xFF2B5F9E)),
                            SizedBox(height: 10),
                            Text(
                              "Tekan untuk memilih Screenshot",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2B5F9E),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Format: PNG, JPG, JPEG",
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // --- Submit Button ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B5F9E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submitOrder,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Kirim ke Penjual",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrisCard(String amount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2_rounded, color: Color(0xFF15243C), size: 28),
              SizedBox(width: 8),
              Text(
                "QRIS PENJUAL",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF15243C),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _sellerQrisUrl != null && _sellerQrisUrl!.isNotEmpty
                ? Image.network(
                    _sellerQrisUrl!,
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                  )
                : Container(
                    width: 220,
                    height: 220,
                    color: const Color(0xFFF8FAFC),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.qr_code_scanner_rounded, size: 80, color: Color(0xFF2B5F9E)),
                        SizedBox(height: 12),
                        Text(
                          "Scan QRIS Toko",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15243C)),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            "Toko: $_sellerAccountHolder",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF15243C)),
          ),
          const SizedBox(height: 4),
          Text(
            "Total Tagihan: $amount",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF2B5F9E)),
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded, color: Color(0xFF2B5F9E), size: 24),
              const SizedBox(width: 8),
              Text(
                _sellerBankName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15243C),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          const Text(
            "Nomor Rekening",
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _sellerAccountNumber,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF15243C),
                  letterSpacing: 1.2,
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _sellerAccountNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nomor rekening berhasil disalin!')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.copy_rounded, size: 14, color: Color(0xFF2B5F9E)),
                      SizedBox(width: 4),
                      Text(
                        "Salin",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2B5F9E)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Nama Pemilik Rekening",
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 2),
          Text(
            _sellerAccountHolder,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF15243C)),
          ),
        ],
      ),
    );
  }

  Widget _buildCashCard(String amount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.payments_outlined, color: Colors.green, size: 48),
          const SizedBox(height: 12),
          const Text(
            "Pembayaran Tunai (COD)",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF15243C)),
          ),
          const SizedBox(height: 6),
          Text(
            "Silakan siapkan uang tunai sebesar $amount saat bertemu dengan penjual.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
        ],
      ),
    );
  }
}
