import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditStoreProfilePage extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  const EditStoreProfilePage({super.key, this.profileData});

  @override
  State<EditStoreProfilePage> createState() => _EditStoreProfilePageState();
}

class _EditStoreProfilePageState extends State<EditStoreProfilePage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isUploadingStorePhoto = false;
  bool _isUploadingQris = false;

  // Store Info
  final _storeNameController = TextEditingController();
  final _storeDescriptionController = TextEditingController();
  final _storeLinkController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _storePhoneController = TextEditingController();
  String? _storePhotoUrl;
  String? _qrisUrl;

  // Bank
  final _bankNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankAccountHolderController = TextEditingController();

  // Owner info
  final _ownerNameController = TextEditingController();
  final _ownerUsernameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  String? _ownerPhotoUrl;

  static const _primary = Color(0xFF2B5F9E);
  static const _textDark = Color(0xFF15243C);

  Map<String, dynamic> _parseBio(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    try {
      final decoded = jsonDecode(raw.toString());
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  @override
  void initState() {
    super.initState();
    _prefillFromProfile(widget.profileData);
  }

  void _prefillFromProfile(Map<String, dynamic>? data) {
    if (data == null) return;
    final bio = _parseBio(data['bio']);
    final user = _supabase.auth.currentUser;
    final meta = user?.userMetadata ?? {};

    _storeNameController.text = bio['store_name']?.toString() ?? meta['store_name']?.toString() ?? data['full_name']?.toString() ?? '';
    _storeDescriptionController.text = bio['store_description']?.toString() ?? '';
    _storeLinkController.text = bio['store_link']?.toString() ?? '';
    _storeAddressController.text = bio['store_address']?.toString() ?? '';
    _storePhoneController.text = bio['store_phone']?.toString() ?? data['phone_number']?.toString() ?? '';
    _storePhotoUrl = bio['store_photo_url']?.toString() ?? data['profile_photo_url']?.toString();
    _qrisUrl = data['qris_url']?.toString() ?? bio['qris_url']?.toString();

    _bankNameController.text = data['bank_name']?.toString() ?? 'Bank BCA';
    _bankAccountNumberController.text = data['bank_account_number']?.toString() ?? '';
    _bankAccountHolderController.text = data['bank_account_holder']?.toString() ?? data['full_name']?.toString() ?? '';

    _ownerNameController.text = data['full_name']?.toString() ?? '';
    _ownerUsernameController.text = data['username']?.toString() ?? '';
    _ownerEmailController.text = data['email']?.toString() ?? user?.email ?? '';
    _ownerPhotoUrl = data['profile_photo_url']?.toString();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    _storeLinkController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _bankAccountHolderController.dispose();
    _ownerNameController.dispose();
    _ownerUsernameController.dispose();
    _ownerEmailController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage(String folder) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return null;
    try {
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last.toLowerCase();
      final fileName = '$folder/${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _supabase.storage.from('product_images').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext'),
          );
      return _supabase.storage.from('product_images').getPublicUrl(fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }

  Future<void> _pickStorePhoto() async {
    setState(() => _isUploadingStorePhoto = true);
    final url = await _uploadImage('stores');
    if (url != null && mounted) setState(() => _storePhotoUrl = url);
    if (mounted) setState(() => _isUploadingStorePhoto = false);
  }

  Future<void> _pickQrisImage() async {
    setState(() => _isUploadingQris = true);
    final url = await _uploadImage('qris');
    if (url != null && mounted) setState(() => _qrisUrl = url);
    if (mounted) setState(() => _isUploadingQris = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final bio = _parseBio(widget.profileData?['bio']);
      bio['store_name'] = _storeNameController.text.trim();
      bio['store_description'] = _storeDescriptionController.text.trim();
      bio['store_link'] = _storeLinkController.text.trim();
      bio['store_address'] = _storeAddressController.text.trim();
      bio['store_phone'] = _storePhoneController.text.trim();
      if (_storePhotoUrl != null) bio['store_photo_url'] = _storePhotoUrl;
      if (_qrisUrl != null) bio['qris_url'] = _qrisUrl;

      await _supabase.from('profiles').update({
        'full_name': _ownerNameController.text.trim().isNotEmpty
            ? _ownerNameController.text.trim()
            : _storeNameController.text.trim(),
        'username': _ownerUsernameController.text.trim(),
        'phone_number': _storePhoneController.text.trim(),
        'bio': jsonEncode(bio),
        'qris_url': _qrisUrl,
        'bank_name': _bankNameController.text.trim(),
        'bank_account_number': _bankAccountNumberController.text.trim(),
        'bank_account_holder': _bankAccountHolderController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil toko berhasil disimpan!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Ubah Profil Toko', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            children: [
              // 1. Foto & Info Toko
              _buildCard(
                title: 'Informasi Toko',
                icon: Icons.storefront_rounded,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: const Color(0xFFC8DAEF),
                              backgroundImage: _storePhotoUrl != null && _storePhotoUrl!.isNotEmpty
                                  ? NetworkImage(_storePhotoUrl!)
                                  : null,
                              child: _storePhotoUrl == null || _storePhotoUrl!.isEmpty
                                  ? const Icon(Icons.store_rounded, size: 48, color: _primary)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isUploadingStorePhoto ? null : _pickStorePhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                                  child: _isUploadingStorePhoto
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _isUploadingStorePhoto ? null : _pickStorePhoto,
                          icon: const Icon(Icons.photo_camera_rounded, size: 16, color: _primary),
                          label: Text(
                            _storePhotoUrl != null ? 'Ganti Foto Toko' : 'Upload Foto Toko',
                            style: const TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _field(_storeNameController, 'Nama Toko', Icons.store_rounded,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nama toko wajib diisi' : null),
                  const SizedBox(height: 14),
                  _field(_storeDescriptionController, 'Deskripsi Toko', Icons.description_outlined,
                      maxLines: 3, hint: 'Ceritakan singkat mengenai tokomu...'),
                  const SizedBox(height: 14),
                  _field(_storeLinkController, 'Tautan Toko', Icons.link_rounded,
                      hint: 'https://brawigo.id/toko/namatoko'),
                  const SizedBox(height: 14),
                  _field(_storeAddressController, 'Alamat Toko', Icons.location_on_outlined,
                      maxLines: 2, hint: 'Jl. Sigura-gura No. 12'),
                  const SizedBox(height: 14),
                  _field(_storePhoneController, 'Nomor WhatsApp Toko', Icons.phone_outlined,
                      keyboardType: TextInputType.phone, hint: '08xxxxxxxxxx'),
                ],
              ),
              const SizedBox(height: 16),

              // 2. QRIS
              _buildCard(
                title: 'QRIS Toko',
                icon: Icons.qr_code_2_rounded,
                subtitle: 'Upload QRIS untuk pembayaran langsung.',
                children: [
                  Center(
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 260),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        children: [
                          if (_qrisUrl != null && _qrisUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(_qrisUrl!, height: 190, width: 190, fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => _qrisPlaceholder()),
                            )
                          else
                            _qrisPlaceholder(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isUploadingQris ? null : _pickQrisImage,
                                icon: _isUploadingQris
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.upload_file_rounded, size: 16),
                                label: Text(_qrisUrl != null ? 'Ganti QRIS' : 'Upload QRIS'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              if (_qrisUrl != null && _qrisUrl!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => setState(() => _qrisUrl = null),
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Rekening Bank
              _buildCard(
                title: 'Rekening Bank',
                icon: Icons.account_balance_rounded,
                subtitle: 'Ditampilkan ke pembeli untuk transfer bank.',
                children: [
                  _field(_bankNameController, 'Nama Bank', Icons.account_balance_outlined,
                      hint: 'Bank BCA / BRI / Mandiri'),
                  const SizedBox(height: 14),
                  _field(_bankAccountNumberController, 'Nomor Rekening', Icons.credit_card_rounded,
                      keyboardType: TextInputType.number, hint: '8220192831'),
                  const SizedBox(height: 14),
                  _field(_bankAccountHolderController, 'Atas Nama', Icons.person_pin_rounded,
                      hint: 'Nama pemilik rekening'),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Profil Pemilik
              _buildCard(
                title: 'Profil Pemilik',
                icon: Icons.person_pin_circle_outlined,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFFC8DAEF),
                      backgroundImage: _ownerPhotoUrl != null && _ownerPhotoUrl!.isNotEmpty
                          ? NetworkImage(_ownerPhotoUrl!)
                          : null,
                      child: _ownerPhotoUrl == null || _ownerPhotoUrl!.isEmpty
                          ? const Icon(Icons.person, size: 36, color: _primary)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _field(_ownerNameController, 'Nama Pemilik', Icons.person_outline),
                  const SizedBox(height: 14),
                  _field(_ownerUsernameController, 'Username', Icons.alternate_email),
                  const SizedBox(height: 14),
                  _field(_ownerEmailController, 'Email', Icons.email_outlined, readOnly: true),
                ],
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Simpan Profil Toko',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qrisPlaceholder() {
    return Container(
      height: 170,
      width: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.qr_code_scanner_rounded, size: 56, color: Color(0xFF94A3B8)),
          SizedBox(height: 8),
          Text('Belum ada QRIS', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          SizedBox(height: 2),
          Text('Upload barcode QRIS toko', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE6EDF8), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    int maxLines = 1,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: 14, color: readOnly ? const Color(0xFF64748B) : _textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA0AEC0)),
        prefixIcon: Icon(icon, color: _primary, size: 20),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
      ),
    );
  }
}

