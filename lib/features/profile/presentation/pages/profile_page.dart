import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'package:brawigo/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:brawigo/features/auth/presentation/blocs/auth_event.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = "User belum login";
          _isLoading = false;
        });
        return;
      }

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      final metaRole = user.userMetadata?['role']?.toString().toLowerCase().trim();
      if (metaRole != null && metaRole.isNotEmpty) {
        data['role'] = metaRole;
      }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrawigoColors.blue50,
      appBar: AppBar(
        title: const Text("Profil Saya", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: BrawigoColors.blue700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: BrawigoColors.blue700));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text("Gagal memuat profil: $_errorMessage", textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: BrawigoColors.blue700, foregroundColor: Colors.white),
              onPressed: _fetchProfile,
              child: const Text("Coba Lagi"),
            ),
          ],
        ),
      );
    }

    final data = _profileData;
    if (data == null) {
      return const Center(child: Text("Data profil tidak ditemukan."));
    }

    final fullName = data['full_name'] ?? 'Tanpa Nama';
    final email = data['email'] ?? '-';
    final role = data['role'] ?? 'buyer';
    final username = data['username'] ?? '-';
    final photoUrl = data['profile_photo_url'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Foto Profil
          CircleAvatar(
            radius: 60,
            backgroundColor: BrawigoColors.blue200,
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl == null || photoUrl.isEmpty
                ? const Icon(Icons.person, size: 60, color: BrawigoColors.blue800)
                : null,
          ),
          const SizedBox(height: 16),
          
          // Nama & Role
          Text(
            fullName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: BrawigoColors.blue950),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: role == 'seller' ? BrawigoColors.yellowLight : BrawigoColors.blue100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              role == 'seller' ? 'Penjual (Seller)' : 'Pembeli (Buyer)',
              style: TextStyle(
                color: role == 'seller' ? BrawigoColors.yellowDarkActive : BrawigoColors.blue700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Detail Informasi
          Card(
            elevation: 1,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoRow(Icons.alternate_email, "Username", username),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.email_outlined, "Email", email),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 40),

          // Tombol Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                "Keluar (Logout)",
                style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _confirmLogout(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: BrawigoColors.blue600),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: BrawigoColors.blue950)),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext); // Tutup dialog
              context.read<AuthBloc>().add(LogoutRequested()); // Dispatch event logout
              context.go('/login');
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
