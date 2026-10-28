import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditBuyerProfilePage extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  const EditBuyerProfilePage({super.key, this.profileData});

  @override
  State<EditBuyerProfilePage> createState() => _EditBuyerProfilePageState();
}

class _EditBuyerProfilePageState extends State<EditBuyerProfilePage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  String? _photoUrl;

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
    _prefill(widget.profileData);
  }

  void _prefill(Map<String, dynamic>? data) {
    if (data == null) return;
    final bio = _parseBio(data['bio']);
    final user = _supabase.auth.currentUser;
    final meta = user?.userMetadata ?? {};

    _nameController.text = data['full_name']?.toString() ?? meta['full_name']?.toString() ?? '';
    _usernameController.text = data['username']?.toString() ?? meta['username']?.toString() ?? '';
    _phoneController.text = data['phone_number']?.toString() ?? meta['phone_number']?.toString() ?? '';
    _emailController.text = data['email']?.toString() ?? user?.email ?? '';
    _addressController.text = bio['delivery_address']?.toString() ?? meta['delivery_address']?.toString() ?? '';
    _photoUrl = data['profile_photo_url']?.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
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
          SnackBar(content: Text('Gagal upload foto: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }

  Future<void> _pickPhoto() async {
    setState(() => _isUploadingPhoto = true);
    final url = await _uploadImage('profiles');
    if (url != null && mounted) {
      setState(() => _photoUrl = url);
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('profiles').update({
          'profile_photo_url': url,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
      }
    }
    if (mounted) setState(() => _isUploadingPhoto = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final bio = _parseBio(widget.profileData?['bio']);
      bio['delivery_address'] = _addressController.text.trim();

      await _supabase.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        if (_photoUrl != null) 'profile_photo_url': _photoUrl,
        'bio': jsonEncode(bio),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      await _supabase.auth.updateUser(UserAttributes(data: {
        'full_name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'delivery_address': _addressController.text.trim(),
      }));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil disimpan!'), backgroundColor: Colors.green),
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
        title: const Text('Ubah Profil', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            children: [
              // Foto Profil
              _buildCard(
                title: 'Foto Profil',
                icon: Icons.person_outline_rounded,
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
                              backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                                  ? NetworkImage(_photoUrl!)
                                  : null,
                              child: _photoUrl == null || _photoUrl!.isEmpty
                                  ? const Icon(Icons.person, size: 48, color: _primary)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isUploadingPhoto ? null : _pickPhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                                  child: _isUploadingPhoto
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
                          onPressed: _isUploadingPhoto ? null : _pickPhoto,
                          icon: const Icon(Icons.photo_camera_rounded, size: 16, color: _primary),
                          label: const Text('Ganti Foto Profil',
                              style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Informasi Pribadi
              _buildCard(
                title: 'Informasi Pribadi',
                icon: Icons.badge_outlined,
                children: [
                  _field(_nameController, 'Nama Lengkap', Icons.person_outline,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null),
                  const SizedBox(height: 14),
                  _field(_usernameController, 'Username', Icons.alternate_email, validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Username wajib diisi';
                    if (v.trim().length < 3) return 'Username minimal 3 karakter';
                    return null;
                  }),
                  const SizedBox(height: 14),
                  _field(_phoneController, 'Nomor Telepon', Icons.phone_outlined,
                      keyboardType: TextInputType.phone, hint: '08xxxxxxxxxx'),
                  const SizedBox(height: 14),
                  _field(_emailController, 'Email', Icons.email_outlined,
                      readOnly: true, helperText: 'Email terikat dengan akun Anda'),
                ],
              ),
              const SizedBox(height: 16),

              // Alamat
              _buildCard(
                title: 'Alamat Pengiriman',
                icon: Icons.local_shipping_outlined,
                subtitle: 'Alamat default saat checkout.',
                children: [
                  _field(_addressController, 'Alamat Lengkap', Icons.location_on_outlined,
                      maxLines: 3, hint: 'Jl. Sigura-gura No. 10, Kec. Lowokwaru, Kota Malang'),
                ],
              ),
              const SizedBox(height: 24),

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
                      : const Text('Simpan Perubahan',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
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
    String? helperText,
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
        helperText: helperText,
        helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
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

