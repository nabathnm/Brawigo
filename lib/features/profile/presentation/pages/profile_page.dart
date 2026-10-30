import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brawigo/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:brawigo/features/auth/presentation/blocs/auth_event.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatefulWidget {
  final bool isSeller;

  const ProfilePage({super.key, this.isSeller = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;

  late bool _isSellerView;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _isUploadingStorePhoto = false;
  bool _isUploadingQris = false;
  String? _errorMessage;

  Map<String, dynamic>? _profileData;

  // Buyer Form Controllers
  final _buyerNameController = TextEditingController();
  final _buyerUsernameController = TextEditingController();
  final _buyerPhoneController = TextEditingController();
  final _buyerEmailController = TextEditingController();
  final _buyerAddressController = TextEditingController();
  String? _buyerPhotoUrl;

  // Seller Form Controllers
  final _storeNameController = TextEditingController();
  final _storeDescriptionController = TextEditingController();
  final _storeLinkController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _storePhoneController = TextEditingController();
  String? _storePhotoUrl;
  String? _qrisUrl;
  final _bankNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankAccountHolderController = TextEditingController();

  // Seller Owner Info
  final _sellerOwnerNameController = TextEditingController();
  final _sellerOwnerUsernameController = TextEditingController();
  final _sellerOwnerEmailController = TextEditingController();
  String? _sellerOwnerPhotoUrl;

  final _buyerFormKey = GlobalKey<FormState>();
  final _sellerFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _isSellerView = widget.isSeller;
    _fetchProfile();
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _buyerUsernameController.dispose();
    _buyerPhoneController.dispose();
    _buyerEmailController.dispose();
    _buyerAddressController.dispose();

    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    _storeLinkController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _bankAccountHolderController.dispose();

    _sellerOwnerNameController.dispose();
    _sellerOwnerUsernameController.dispose();
    _sellerOwnerEmailController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _parseBio(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    try {
      final decoded = jsonDecode(raw.toString());
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  Future<void> _fetchProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _errorMessage = "User belum login";
            _isLoading = false;
          });
        }
        return;
      }

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        if (mounted) {
          setState(() {
            _errorMessage = "Data profil tidak ditemukan.";
            _isLoading = false;
          });
        }
        return;
      }

      final bioMap = _parseBio(data['bio']);
      final meta = user.userMetadata ?? {};

      final fullName = data['full_name']?.toString() ?? meta['full_name']?.toString() ?? '';
      final username = data['username']?.toString() ?? meta['username']?.toString() ?? '';
      final phone = data['phone_number']?.toString() ?? meta['phone_number']?.toString() ?? '';
      final email = data['email']?.toString() ?? (user.email ?? '');
      final photoUrl = data['profile_photo_url']?.toString();

      // Buyer prefill
      _buyerNameController.text = fullName;
      _buyerUsernameController.text = username;
      _buyerPhoneController.text = phone;
      _buyerEmailController.text = email;
      _buyerAddressController.text = bioMap['delivery_address']?.toString() ??
          meta['delivery_address']?.toString() ??
          '';
      _buyerPhotoUrl = photoUrl;

      // Seller prefill
      _storeNameController.text = bioMap['store_name']?.toString() ??
          meta['store_name']?.toString() ??
          (username.isNotEmpty ? username : fullName);
      _storeDescriptionController.text = bioMap['store_description']?.toString() ??
          meta['store_description']?.toString() ??
          '';
      _storeLinkController.text = bioMap['store_link']?.toString() ??
          meta['store_link']?.toString() ??
          '';
      _storeAddressController.text = bioMap['store_address']?.toString() ??
          meta['store_address']?.toString() ??
          '';
      _storePhoneController.text = bioMap['store_phone']?.toString() ??
          meta['store_phone']?.toString() ??
          phone;
      _storePhotoUrl = bioMap['store_photo_url']?.toString() ??
          meta['store_photo_url']?.toString() ??
          photoUrl;

      _qrisUrl = data['qris_url']?.toString() ?? bioMap['qris_url']?.toString();
      _bankNameController.text = data['bank_name']?.toString() ??
          meta['bank_name']?.toString() ??
          'Bank BCA';
      _bankAccountNumberController.text = data['bank_account_number']?.toString() ??
          meta['bank_account_number']?.toString() ??
          '';
      _bankAccountHolderController.text = data['bank_account_holder']?.toString() ??
          meta['bank_account_holder']?.toString() ??
          fullName;

      _sellerOwnerNameController.text = fullName;
      _sellerOwnerUsernameController.text = username;
      _sellerOwnerEmailController.text = email;
      _sellerOwnerPhotoUrl = photoUrl;

      if (mounted) {
        setState(() {
          _profileData = data;
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

  Future<String?> _uploadImage(String folder) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
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

      final publicUrl = _supabase.storage.from('product_images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah gambar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _pickBuyerPhoto() async {
    setState(() => _isUploadingPhoto = true);
    final url = await _uploadImage('profiles');
    if (url != null && mounted) {
      setState(() => _buyerPhotoUrl = url);
      // Langsung simpan foto profil ke DB
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('profiles').update({
          'profile_photo_url': url,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
    if (mounted) setState(() => _isUploadingPhoto = false);
  }

  Future<void> _pickStorePhoto() async {
    setState(() => _isUploadingStorePhoto = true);
    final url = await _uploadImage('stores');
    if (url != null && mounted) {
      setState(() => _storePhotoUrl = url);
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final bioMap = _parseBio(_profileData?['bio']);
        bioMap['store_photo_url'] = url;
        await _supabase.from('profiles').update({
          'bio': jsonEncode(bioMap),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
        _profileData?['bio'] = jsonEncode(bioMap);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto toko berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
    if (mounted) setState(() => _isUploadingStorePhoto = false);
  }

  Future<void> _pickQrisImage() async {
    setState(() => _isUploadingQris = true);
    final url = await _uploadImage('qris');
    if (url != null && mounted) {
      setState(() => _qrisUrl = url);
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final bioMap = _parseBio(_profileData?['bio']);
        bioMap['qris_url'] = url;
        await _supabase.from('profiles').update({
          'qris_url': url,
          'bio': jsonEncode(bioMap),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
        _profileData?['qris_url'] = url;
        _profileData?['bio'] = jsonEncode(bioMap);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QRIS toko berhasil diunggah!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
    if (mounted) setState(() => _isUploadingQris = false);
  }

  Future<void> _saveBuyerProfile() async {
    if (!_buyerFormKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final bioMap = _parseBio(_profileData?['bio']);
      bioMap['delivery_address'] = _buyerAddressController.text.trim();

      await _supabase.from('profiles').update({
        'full_name': _buyerNameController.text.trim(),
        'username': _buyerUsernameController.text.trim(),
        'phone_number': _buyerPhoneController.text.trim(),
        if (_buyerPhotoUrl != null) 'profile_photo_url': _buyerPhotoUrl,
        'bio': jsonEncode(bioMap),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': _buyerNameController.text.trim(),
            'username': _buyerUsernameController.text.trim(),
            'phone_number': _buyerPhoneController.text.trim(),
            'delivery_address': _buyerAddressController.text.trim(),
          },
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil pembeli berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan profil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveSellerProfile() async {
    if (!_sellerFormKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final bioMap = _parseBio(_profileData?['bio']);
      bioMap['store_name'] = _storeNameController.text.trim();
      bioMap['store_description'] = _storeDescriptionController.text.trim();
      bioMap['store_link'] = _storeLinkController.text.trim();
      bioMap['store_address'] = _storeAddressController.text.trim();
      bioMap['store_phone'] = _storePhoneController.text.trim();
      if (_storePhotoUrl != null) bioMap['store_photo_url'] = _storePhotoUrl;
      if (_qrisUrl != null) bioMap['qris_url'] = _qrisUrl;

      await _supabase.from('profiles').update({
        'full_name': _sellerOwnerNameController.text.trim().isNotEmpty
            ? _sellerOwnerNameController.text.trim()
            : _storeNameController.text.trim(),
        'username': _sellerOwnerUsernameController.text.trim(),
        'phone_number': _storePhoneController.text.trim(),
        'bio': jsonEncode(bioMap),
        'qris_url': _qrisUrl,
        'bank_name': _bankNameController.text.trim(),
        'bank_account_number': _bankAccountNumberController.text.trim(),
        'bank_account_holder': _bankAccountHolderController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'store_name': _storeNameController.text.trim(),
            'store_address': _storeAddressController.text.trim(),
            'store_phone': _storePhoneController.text.trim(),
            'store_photo_url': _storePhotoUrl,
            'bank_name': _bankNameController.text.trim(),
            'bank_account_number': _bankAccountNumberController.text.trim(),
            'bank_account_holder': _bankAccountHolderController.text.trim(),
          },
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan toko & pembayaran berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan toko: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi Keluar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(LogoutRequested());
              context.go('/login');
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
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
        title: Text(
          _isSellerView ? "Pengaturan Toko & Profil" : "Profil Saya",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF15243C),
            fontSize: 18,
          ),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2B5F9E)))
            : _errorMessage != null
                ? _buildErrorView()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    child: _isSellerView ? _buildSellerProfile() : _buildBuyerProfile(),
                  ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              "Gagal memuat profil: $_errorMessage",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF15243C), fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B5F9E),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchProfile();
              },
              child: const Text("Coba Lagi"),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // BUYER PROFILE VIEW
  // =========================================================================
  Widget _buildBuyerProfile() {
    return Form(
      key: _buyerFormKey,
      child: Column(
        children: [
          // Header Avatar Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: const Color(0xFFC8DAEF),
                      backgroundImage: _buyerPhotoUrl != null && _buyerPhotoUrl!.isNotEmpty
                          ? NetworkImage(_buyerPhotoUrl!)
                          : null,
                      child: _buyerPhotoUrl == null || _buyerPhotoUrl!.isEmpty
                          ? const Icon(Icons.person, size: 48, color: Color(0xFF2B5F9E))
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingPhoto ? null : _pickBuyerPhoto,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2B5F9E),
                            shape: BoxShape.circle,
                          ),
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
                const SizedBox(height: 12),
                Text(
                  _buyerNameController.text.isNotEmpty ? _buyerNameController.text : "Pengguna Brawigo",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15243C),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6EDF8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Pembeli (Buyer)",
                    style: TextStyle(
                      color: Color(0xFF2B5F9E),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Biodata Card
          _buildCard(
            title: "Informasi Pribadi",
            icon: Icons.person_outline_rounded,
            children: [
              _buildTextField(
                controller: _buyerNameController,
                label: "Nama Lengkap",
                icon: Icons.badge_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama lengkap wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _buyerUsernameController,
                label: "Username",
                icon: Icons.alternate_email,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Username wajib diisi';
                  if (v.trim().length < 3) return 'Username minimal 3 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _buyerPhoneController,
                label: "Nomor Telepon / WhatsApp",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                hint: "08xxxxxxxxxx",
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _buyerEmailController,
                label: "Email",
                icon: Icons.email_outlined,
                readOnly: true,
                helperText: "Email terikat dengan akun Anda",
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Shipping Address Card
          _buildCard(
            title: "Alamat Pengiriman Utama",
            icon: Icons.local_shipping_outlined,
            subtitle: "Alamat ini akan otomatis terisi saat Anda checkout untuk mempercepat transaksi.",
            children: [
              _buildTextField(
                controller: _buyerAddressController,
                label: "Alamat Lengkap",
                icon: Icons.location_on_outlined,
                maxLines: 3,
                hint: "Contoh: Jl. Sigura-gura No. 10, RT 02/RW 03, Kel. Sumbersari, Kec. Lowokwaru, Kota Malang",
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveBuyerProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B5F9E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      "Simpan Perubahan",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // Logout Button
          _buildLogoutButton(),
        ],
      ),
    );
  }

  // =========================================================================
  // SELLER PROFILE VIEW
  // =========================================================================
  Widget _buildSellerProfile() {
    return Form(
      key: _sellerFormKey,
      child: Column(
        children: [
          // 1. PENGATURAN TOKO
          _buildCard(
            title: "Pengaturan Toko",
            icon: Icons.storefront_rounded,
            subtitle: "Atur identitas toko Anda. Nama dan foto toko akan ditampilkan ke pembeli pada detail produk.",
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
                              ? const Icon(Icons.store_rounded, size: 48, color: Color(0xFF2B5F9E))
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUploadingStorePhoto ? null : _pickStorePhoto,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2B5F9E),
                                shape: BoxShape.circle,
                              ),
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
                      icon: const Icon(Icons.photo_camera_rounded, size: 16, color: Color(0xFF2B5F9E)),
                      label: Text(
                        _storePhotoUrl != null ? "Ganti Foto Toko" : "Upload Foto Toko",
                        style: const TextStyle(color: Color(0xFF2B5F9E), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _storeNameController,
                label: "Nama Toko",
                icon: Icons.store_rounded,
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama toko wajib diisi' : null,
                helperText: "Nama ini yang akan muncul di bawah detail produk pembeli",
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _storeDescriptionController,
                label: "Deskripsi Toko",
                icon: Icons.description_outlined,
                maxLines: 3,
                hint: "Ceritakan singkat mengenai tokomu...",
                helperText: "Deskripsi ini akan muncul di profil tokomu",
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _storeLinkController,
                label: "Tautan Toko",
                icon: Icons.link_rounded,
                hint: "brawigo.id/toko/namatoko",
                helperText: "Tautan profil toko untuk dibagikan ke calon pembeli",
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _storeAddressController,
                label: "Alamat Toko",
                icon: Icons.location_on_outlined,
                maxLines: 2,
                hint: "Contoh: Kantin CL Lt. 2 FILKOM UB / Jl. Sigura-gura No. 12",
                helperText: "Alamat ini digunakan jika pembeli memilih 'Ambil di Toko'",
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _storePhoneController,
                label: "Nomor WhatsApp Toko",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                hint: "08xxxxxxxxxx",
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. PENGATURAN QRIS TOKO
          _buildCard(
            title: "Pengaturan QRIS Toko",
            icon: Icons.qr_code_2_rounded,
            subtitle: "Upload gambar barcode QRIS toko Anda. QRIS ini akan otomatis ditampilkan ke pembeli saat checkout.",
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
                          child: Image.network(
                            _qrisUrl!,
                            height: 190,
                            width: 190,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => _buildQrisPlaceholder(),
                          ),
                        )
                      else
                        _buildQrisPlaceholder(),
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
                            label: Text(_qrisUrl != null ? "Ganti QRIS" : "Upload QRIS"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2B5F9E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          if (_qrisUrl != null && _qrisUrl!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                setState(() => _qrisUrl = null);
                              },
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              tooltip: "Hapus QRIS",
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

          // 3. PENGATURAN REKENING BANK
          _buildCard(
            title: "Rekening Bank Toko",
            icon: Icons.account_balance_rounded,
            subtitle: "Rekening bank yang akan ditampilkan ke pembeli untuk metode Transfer Bank.",
            children: [
              _buildTextField(
                controller: _bankNameController,
                label: "Nama Bank",
                icon: Icons.account_balance_outlined,
                hint: "Contoh: Bank BCA / Bank BRI / Bank Mandiri",
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _bankAccountNumberController,
                label: "Nomor Rekening",
                icon: Icons.credit_card_rounded,
                keyboardType: TextInputType.number,
                hint: "Contoh: 8220192831",
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _bankAccountHolderController,
                label: "Atas Nama (Nama Pemilik Rekening)",
                icon: Icons.person_pin_rounded,
                hint: "Contoh: Budi Santoso",
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. INFORMASI AKUN PENJUAL
          _buildCard(
            title: "Profil Pemilik Akun",
            icon: Icons.person_pin_circle_outlined,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFFC8DAEF),
                  backgroundImage: _sellerOwnerPhotoUrl != null && _sellerOwnerPhotoUrl!.isNotEmpty
                      ? NetworkImage(_sellerOwnerPhotoUrl!)
                      : null,
                  child: _sellerOwnerPhotoUrl == null || _sellerOwnerPhotoUrl!.isEmpty
                      ? const Icon(Icons.person, size: 36, color: Color(0xFF2B5F9E))
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _sellerOwnerNameController,
                label: "Nama Pemilik",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _sellerOwnerUsernameController,
                label: "Username",
                icon: Icons.alternate_email,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _sellerOwnerEmailController,
                label: "Email",
                icon: Icons.email_outlined,
                readOnly: true,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSellerProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B5F9E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      "Simpan Pengaturan Toko",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // Logout Button
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildQrisPlaceholder() {
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
          Text(
            "Belum ada QRIS",
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2),
          Text(
            "Upload barcode QRIS toko",
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // REUSABLE COMPONENTS
  // =========================================================================
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EDF8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF2B5F9E), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15243C),
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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
      style: TextStyle(
        fontSize: 14,
        color: readOnly ? const Color(0xFF64748B) : const Color(0xFF15243C),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA0AEC0)),
        helperText: helperText,
        helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        helperMaxLines: 2,
        prefixIcon: Icon(icon, color: const Color(0xFF2B5F9E), size: 20),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2B5F9E), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
        label: const Text(
          "Keluar (Logout)",
          style: TextStyle(
            color: Colors.red,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _confirmLogout(context),
      ),
    );
  }
}
