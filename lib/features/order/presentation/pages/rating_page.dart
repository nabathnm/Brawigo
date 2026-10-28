import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/widgets/brawigo_toast.dart';

class RatingPage extends StatefulWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic>? existingReview;

  const RatingPage({
    super.key,
    required this.order,
    this.existingReview,
  });

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  final _supabase = Supabase.instance.client;
  int _rating = 5;
  final _commentController = TextEditingController();
  final List<XFile> _selectedPhotos = [];
  List<String> _existingPhotoUrls = [];
  bool _isSubmitting = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _rating = (widget.existingReview!['rating'] as num?)?.toInt() ?? 5;
      final rawComment = widget.existingReview!['comment']?.toString() ?? '';
      try {
        if (rawComment.startsWith('{') && rawComment.contains('"text"')) {
          final parsed = jsonDecode(rawComment);
          _commentController.text = parsed['text']?.toString() ?? '';
          if (parsed['photos'] is List) {
            _existingPhotoUrls = List<String>.from(parsed['photos']);
          }
        } else {
          _commentController.text = rawComment;
        }
      } catch (_) {
        _commentController.text = rawComment;
      }
      _isEditMode = false; // Tampilkan mode preview dulu jika sudah ada review
    } else {
      _isEditMode = true; // Mode create baru
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final totalPhotos = _selectedPhotos.length + _existingPhotoUrls.length;
    if (totalPhotos >= 4) {
      BrawigoToast.showWarning(
        context,
        message: 'Maksimal 4 foto untuk penilaian transaksi.',
        title: 'Maksimal Foto',
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null && mounted) {
      setState(() {
        _selectedPhotos.add(picked);
      });
    }
  }

  Future<void> _submitReview() async {
    if (_rating <= 0) {
      BrawigoToast.showWarning(
        context,
        message: 'Silakan pilih rating bintang terlebih dahulu.',
        title: 'Rating Diperlukan',
      );
      return;
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      BrawigoToast.showError(
        context,
        message: 'Silakan login terlebih dahulu.',
        title: 'Belum Masuk',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final orderId = widget.order['id'];
      final productId = widget.order['product_id'];

      // Upload foto baru jika ada
      final List<String> uploadedUrls = List<String>.from(_existingPhotoUrls);
      for (final photo in _selectedPhotos) {
        final bytes = await photo.readAsBytes();
        final ext = photo.name.split('.').last.toLowerCase();
        final fileName = 'reviews/${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}_${photo.name}';
        await _supabase.storage.from('product_images').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$ext'),
        );
        final publicUrl = _supabase.storage.from('product_images').getPublicUrl(fileName);
        uploadedUrls.add(publicUrl);
      }

      // Format comment with JSON structure for text + photos
      final commentPayload = jsonEncode({
        'text': _commentController.text.trim(),
        'photos': uploadedUrls,
      });

      if (widget.existingReview != null) {
        // UPDATE existing review
        await _supabase.from('reviews').update({
          'rating': _rating,
          'comment': commentPayload,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', widget.existingReview!['id']);
      } else {
        // INSERT new review
        await _supabase.from('reviews').insert({
          'order_id': orderId,
          'product_id': productId,
          'reviewer_id': currentUser.id,
          'rating': _rating,
          'comment': commentPayload,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        BrawigoToast.showSuccess(
          context,
          message: 'Terima kasih atas penilaian dan ulasan Anda!',
          title: 'Penilaian Berhasil Dikirim',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        BrawigoToast.showError(
          context,
          message: e,
          title: 'Gagal Menyimpan Penilaian',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.order['id']?.toString() ?? '-';
    final shortOrderId = orderId.length > 8 ? 'ID${orderId.substring(0, 8).toUpperCase()}' : 'ID$orderId';

    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: const Color(0xFF15243C),
          centerTitle: true,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            children: [
              const Text(
                'Penilaian Transaksi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF15243C)),
              ),
              Text(
                shortOrderId,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Box Rating Bintang
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditMode ? 'Beri penilaian untuk transaksi ini' : 'Penilaian kamu',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15243C),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starNum = index + 1;
                          final isFilled = starNum <= _rating;
                          return GestureDetector(
                            onTap: _isEditMode
                                ? () {
                                    setState(() {
                                      _rating = starNum;
                                    });
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 40,
                                color: isFilled ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Box Pengalaman Transaksi
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditMode ? 'Bagaimana pengalaman transaksi ini?' : 'Pengalaman transaksi',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15243C),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _isEditMode
                          ? Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: TextField(
                                controller: _commentController,
                                maxLines: 4,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF15243C)),
                                decoration: const InputDecoration(
                                  hintText: 'Ceritakan di sini...',
                                  hintStyle: TextStyle(color: Color(0xFFA0AEC0), fontSize: 13),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(12),
                                ),
                              ),
                            )
                          : Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                _commentController.text.isNotEmpty
                                    ? _commentController.text
                                    : 'Tidak ada ulasan tertulis.',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Box Kirim Foto Transaksi
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _isEditMode ? 'Kirim foto untuk transaksi ini' : 'Foto untuk transaksi ini',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15243C),
                            ),
                          ),
                          if (_isEditMode) ...[
                            const SizedBox(width: 6),
                            const Text(
                              '*optional',
                              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Photos thumbnails row
                      if (_existingPhotoUrls.isNotEmpty || _selectedPhotos.isNotEmpty) ...[
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ..._existingPhotoUrls.map((url) => _buildPhotoItem(
                              imageWidget: Image.network(url, width: 68, height: 68, fit: BoxFit.cover),
                              onRemove: _isEditMode
                                  ? () => setState(() => _existingPhotoUrls.remove(url))
                                  : null,
                            )),
                            ..._selectedPhotos.map((file) => _buildPhotoItem(
                              imageWidget: kIsWeb
                                  ? Image.network(file.path, width: 68, height: 68, fit: BoxFit.cover)
                                  : Image.asset(file.path, width: 68, height: 68, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 36, color: Colors.grey)),
                              onRemove: _isEditMode
                                  ? () => setState(() => _selectedPhotos.remove(file))
                                  : null,
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Add photo button when in edit mode
                      if (_isEditMode && (_selectedPhotos.length + _existingPhotoUrls.length) < 4) ...[
                        InkWell(
                          onTap: _pickPhoto,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 60,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_rounded, color: Color(0xFF64748B), size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'Tambahkan Foto',
                                  style: TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Maksimal 4 foto',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Tombol Aksi Bawah
                if (_isEditMode) ...[
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B5F9E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _isSubmitting ? null : _submitReview,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              widget.existingReview != null ? 'Simpan Perubahan' : 'Kirim Penilaian',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ),
                ] else ...[
                  // Mode Preview / Sudah dinilai: Tombol Ubah Penilaian & Kembali
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2B5F9E),
                              side: const BorderSide(color: Color(0xFF2B5F9E)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2B5F9E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              setState(() {
                                _isEditMode = true;
                              });
                            },
                            child: const Text('Ubah Penilaian', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoItem({required Widget imageWidget, VoidCallback? onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 68,
            height: 68,
            child: imageWidget,
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
              ),
            ),
          ),
      ],
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
}

