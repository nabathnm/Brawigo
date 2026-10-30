import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brawigo/core/widgets/brawigo_toast.dart';

class ReportUserPage extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String? sellerPhoto;
  final String? productId;

  const ReportUserPage({
    super.key,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhoto,
    this.productId,
  });

  @override
  State<ReportUserPage> createState() => _ReportUserPageState();
}

class EvidenceItem {
  final XFile file;
  final Uint8List bytes;
  EvidenceItem({required this.file, required this.bytes});
}

class _ReportUserPageState extends State<ReportUserPage> {
  final _supabase = Supabase.instance.client;
  final _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  int _currentStep = 1; // 1: Pick reason, 2: Fill form
  String? _selectedReason;
  final List<EvidenceItem> _evidenceItems = [];
  bool _isSubmitting = false;

  final List<String> _reportReasons = [
    'Menjual Produk Terlarang',
    'Penipuan',
    'Pelanggaran Privasi',
    'Pesanan Palsu',
    'Lainnya',
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidenceImages() async {
    if (_evidenceItems.length >= 6) {
      BrawigoToast.showWarning(context, title: 'Batas File', message: 'Maksimal 6 file bukti yang dapat diunggah.');
      return;
    }

    try {
      final picked = await _picker.pickMultiImage(
        imageQuality: 80,
      );
      if (picked.isNotEmpty) {
        for (final img in picked) {
          if (_evidenceItems.length < 6) {
            final bytes = await img.readAsBytes();
            _evidenceItems.add(EvidenceItem(file: img, bytes: bytes));
          }
        }
        if (mounted) setState(() {});
      }
    } catch (_) {
      try {
        final single = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (single != null && _evidenceItems.length < 6) {
          final bytes = await single.readAsBytes();
          _evidenceItems.add(EvidenceItem(file: single, bytes: bytes));
          if (mounted) setState(() {});
        }
      } catch (e) {
        if (mounted) {
          BrawigoToast.showError(context, title: 'Gagal', message: 'Gagal memilih gambar: $e');
        }
      }
    }
  }

  void _removeEvidenceImage(int index) {
    setState(() {
      _evidenceItems.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      BrawigoToast.showWarning(context, title: 'Perlu Login', message: 'Silakan login terlebih dahulu untuk melapor.');
      return;
    }

    if (_descController.text.trim().isEmpty) {
      BrawigoToast.showWarning(context, title: 'Wajib Diisi', message: 'Mohon isi deskripsi laporan.');
      return;
    }

    if (_evidenceItems.isEmpty) {
      BrawigoToast.showWarning(context, title: 'Wajib Diisi', message: 'Mohon sertakan minimal 1 bukti foto.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final List<String> uploadedUrls = [];

      // 1. Upload foto bukti ke storage
      for (int i = 0; i < _evidenceItems.length; i++) {
        final item = _evidenceItems[i];
        try {
          final fileBytes = item.bytes;
          final ext = item.file.name.split('.').last;
          final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
          final storagePath = 'reports/$fileName';

          await _supabase.storage.from('product_images').uploadBinary(
                storagePath,
                fileBytes,
                fileOptions: const FileOptions(upsert: true),
              );

          final publicUrl = _supabase.storage.from('product_images').getPublicUrl(storagePath);
          uploadedUrls.add(publicUrl);
        } catch (_) {
          // Fallback data url jika bucket storage khusus belum terbuka
          try {
            final bytes = item.bytes;
            final b64 = base64Encode(bytes);
            uploadedUrls.add('data:image/jpeg;base64,$b64');
          } catch (_) {}
        }
      }

      // 2. Simpan ke database: tabel product_reports jika productId tersedia
      String? prodId = widget.productId;
      if (prodId == null) {
        // Ambil produk pertama seller jika ada
        final pRes = await _supabase.from('products').select('id').eq('seller_id', widget.sellerId).limit(1);
        if ((pRes as List).isNotEmpty) {
          prodId = pRes.first['id']?.toString();
        }
      }

      if (prodId != null) {
        try {
          await _supabase.from('product_reports').insert({
            'product_id': prodId,
            'reporter_id': currentUserId,
            'reason': _selectedReason ?? 'Laporan Toko',
            'description': _descController.text.trim(),
            'status': 'pending',
          });
        } catch (e) {
          debugPrint('Error inserting to product_reports: $e');
        }
      }

      // 3. Simpan ke seller profile JSON (store_reports) agar data tersimpan konsisten
      try {
        final sellerProfileRes = await _supabase
            .from('profiles')
            .select('bio')
            .eq('id', widget.sellerId)
            .maybeSingle();

        Map<String, dynamic> bioMap = {};
        final rawBio = sellerProfileRes?['bio']?.toString() ?? '';
        if (rawBio.trim().startsWith('{')) {
          try {
            final parsed = jsonDecode(rawBio);
            if (parsed is Map<String, dynamic>) {
              bioMap = parsed;
            }
          } catch (_) {}
        } else if (rawBio.isNotEmpty) {
          bioMap['store_description'] = rawBio;
        }

        final List existingReports = (bioMap['store_reports'] as List?) ?? [];
        existingReports.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'reporter_id': currentUserId,
          'reason': _selectedReason ?? 'Lainnya',
          'description': _descController.text.trim(),
          'images': uploadedUrls,
          'created_at': DateTime.now().toIso8601String(),
          'status': 'Menunggu Tindakan',
        });

        bioMap['store_reports'] = existingReports;
        bioMap['store_reports_count'] = existingReports.length;

        await _supabase.from('profiles').update({
          'bio': jsonEncode(bioMap),
        }).eq('id', widget.sellerId);
      } catch (e) {
        debugPrint('Error saving store_reports to profile bio: $e');
      }

      if (mounted) {
        BrawigoToast.showSuccess(
          context,
          title: 'Laporan Dikirim',
          message: 'Laporan Anda telah berhasil kami terima dan akan segera ditinjau oleh tim kami.',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        BrawigoToast.showError(context, title: 'Gagal Mengirim', message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF3FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF15243C),
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() => _currentStep = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Laporkan Pengguna ini',
          style: TextStyle(
            color: Color(0xFF15243C),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: _currentStep == 1 ? _buildStep1PickReason() : _buildStep2FillForm(),
    );
  }

  // Stage 1: Pilih Alasan (Sesuai Gambar 3 Kiri)
  Widget _buildStep1PickReason() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Pilih Alasan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A60),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reportReasons.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final reason = _reportReasons[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedReason = reason;
                      _currentStep = 2;
                    });
                  },
                  borderRadius: BorderRadius.vertical(
                    top: index == 0 ? const Radius.circular(16) : Radius.zero,
                    bottom: index == _reportReasons.length - 1 ? const Radius.circular(16) : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          reason,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Stage 2 & 3: Formulir Pelaporan & Upload Bukti (Sesuai Gambar 3 Tengah & Kanan)
  Widget _buildStep2FillForm() {
    final bool isFilled = _descController.text.trim().isNotEmpty && _evidenceItems.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul Alasan yang dipilih
          Text(
            _selectedReason ?? 'Laporan Toko',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A60),
            ),
          ),
          const SizedBox(height: 16),

          // Label Deskripsi Laporan*
          RichText(
            text: const TextSpan(
              text: 'Deskripsi Laporan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A60),
              ),
              children: [
                TextSpan(text: '*', style: TextStyle(color: Color(0xFFEF4444))),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Textbox Deskripsi Laporan
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _descController,
                  maxLines: 5,
                  maxLength: 250,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF15243C), height: 1.4),
                  decoration: const InputDecoration(
                    hintText: 'Mohon uraikan lebih lanjut alasan yang kamu pilih',
                    hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '${_descController.text.length}/100',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Label Upload Bukti*
          RichText(
            text: const TextSpan(
              text: 'Upload Bukti',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A60),
              ),
              children: [
                TextSpan(text: '*', style: TextStyle(color: Color(0xFFEF4444))),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Area Upload Bukti (Dashed / Rounded Container)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFCBD5E1),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                if (_evidenceItems.isNotEmpty) ...[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(_evidenceItems.length, (index) {
                      final item = _evidenceItems[index];
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              item.bytes,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () => _removeEvidenceImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_evidenceItems.length < 6)
                  InkWell(
                    onTap: _pickEvidenceImages,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF94A3B8), width: 1),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, color: Color(0xFF64748B), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Tambahkan File',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Hingga 6 file, maks. 5 mb per file.',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ),

          const SizedBox(height: 36),

          // Tombol Kirim (Sesuai Gambar 3: Biru muda saat belum lengkap, Biru gradien saat lengkap)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: isFilled
                    ? const LinearGradient(
                        colors: [Color(0xFF265896), Color(0xFF1B4171)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                color: isFilled ? null : const Color(0xFF9FBEE0),
              ),
              child: ElevatedButton(
                onPressed: (isFilled && !_isSubmitting) ? _submitReport : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Kirim',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

