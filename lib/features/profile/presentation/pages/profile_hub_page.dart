import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brawigo/core/widgets/brawigo_toast.dart';
import 'package:brawigo/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:brawigo/features/auth/presentation/blocs/auth_event.dart';
import 'package:brawigo/features/marketplace/presentation/pages/manage_products_page.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_event.dart';
import 'package:brawigo/features/marketplace/presentation/pages/wishlist_page.dart';
import 'edit_store_profile_page.dart';
import 'edit_buyer_profile_page.dart';

class ProfileHubPage extends StatefulWidget {
  final bool isSeller;
  const ProfileHubPage({super.key, this.isSeller = false});

  @override
  State<ProfileHubPage> createState() => _ProfileHubPageState();
}

class _ProfileHubPageState extends State<ProfileHubPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  String? _displayName;
  String? _subtitle;
  String? _email;
  String? _photoUrl;
  bool _isDeleting = false;

  static const _primary = Color(0xFF2B5F9E);
  static const _textDark = Color(0xFF15243C);
  static const _cardBg = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
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
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        final bio = _parseBio(data['bio']);
        final studyProg = data['study_program']?.toString();
        final faculty = data['faculty']?.toString();

        String academicSub = '';
        if (studyProg != null && studyProg.isNotEmpty && faculty != null && faculty.isNotEmpty) {
          academicSub = '$studyProg · $faculty';
        } else if (studyProg != null && studyProg.isNotEmpty) {
          academicSub = studyProg;
        } else if (faculty != null && faculty.isNotEmpty) {
          academicSub = faculty;
        }

        setState(() {
          _profile = data;
          if (widget.isSeller) {
            _displayName = bio['store_name']?.toString().isNotEmpty == true
                ? bio['store_name']
                : (data['full_name']?.toString() ?? 'Toko Brawigo');
            _subtitle = academicSub.isNotEmpty
                ? academicSub
                : (data['full_name']?.toString() ?? 'Penjual Brawigo');
          } else {
            _displayName = data['full_name']?.toString() ?? 'Pengguna Brawigo';
            _subtitle = academicSub.isNotEmpty
                ? academicSub
                : (data['username'] != null && data['username'].toString().isNotEmpty
                    ? '@${data['username']}'
                    : 'Mahasiswa Universitas Brawijaya');
          }
          _email = data['email']?.toString() ?? user.email ?? '';
          _photoUrl = widget.isSeller
              ? (bio['store_photo_url']?.toString() ?? data['profile_photo_url']?.toString())
              : data['profile_photo_url']?.toString();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _hasActiveOrders(String userId) async {
    const activeStatuses = [
      'created',
      'waiting_confirmation',
      'pending',
      'confirmed',
      'waiting_payment_courier',
      'waiting_pickup',
      'on_delivery',
      'waiting_meetup',
      'ready_for_pickup',
    ];
    try {
      if (widget.isSeller) {
        final res = await _supabase
            .from('orders')
            .select('id')
            .eq('seller_id', userId)
            .inFilter('order_status', activeStatuses)
            .limit(1);
        if ((res as List).isNotEmpty) return true;
      }
      final res2 = await _supabase
          .from('orders')
          .select('id')
          .eq('buyer_id', userId)
          .inFilter('order_status', activeStatuses)
          .limit(1);
      return (res2 as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Hapus Akun', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        content: const Text(
          'Tindakan ini akan MENGHAPUS PERMANEN akun Anda, termasuk:\n\n'
          '• Semua data profil seller & buyer\n'
          '• Semua produk yang Anda jual\n'
          '• Semua riwayat transaksi\n'
          '• Data tidak dapat dipulihkan kembali\n\n'
          'Apakah Anda yakin ingin menghapus akun?',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus Akun'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Check active orders
      final hasActive = await _hasActiveOrders(user.id);
      if (hasActive && mounted) {
        setState(() => _isDeleting = false);
        BrawigoToast.showError(
          context,
          title: 'Tidak Dapat Menghapus Akun',
          message: 'Anda masih memiliki transaksi yang sedang berjalan (sebagai pembeli atau penjual).',
        );
        return;
      }

      // Delete products if seller
      if (widget.isSeller) {
        await _supabase.from('products').delete().eq('seller_id', user.id);
      }

      // Mark profile as deleted
      await _supabase.from('profiles').update({
        'deleted_at': DateTime.now().toIso8601String(),
        'full_name': '[AKUN DIHAPUS]',
        'username': 'deleted_${user.id.substring(0, 8)}',
      }).eq('id', user.id);

      // Sign out
      if (mounted) {
        context.read<AuthBloc>().add(LogoutRequested());
        await _supabase.auth.signOut();
        if (mounted) context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        BrawigoToast.showError(
          context,
          title: 'Gagal',
          message: 'Gagal menghapus akun: ${e.toString()}',
        );
      }
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC8DAEF), Color(0xFFE6EDF8), Color(0xFFFAFAFA)],
            stops: [0.0, 0.25, 1.0],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _isDeleting
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: _primary),
                        SizedBox(height: 16),
                        Text('Menghapus akun...', style: TextStyle(color: _primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : SafeArea(
                    bottom: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── "Profile" Title text matching Gambar 1 ─────────
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 14),
                            child: Text(
                              'Profile',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),

                          // ─── Floating User Card matching Gambar 1 ──────────
                          _buildUserCard(),
                          const SizedBox(height: 22),

                          // ─── Akun saya ─────────────────────────────────────
                          _sectionLabel('Akun saya'),
                          const SizedBox(height: 8),
                          _menuCard([
                            _menuTile(
                              icon: Icons.person_rounded,
                              label: widget.isSeller ? 'Ubah Profil Toko' : 'Ubah Profil',
                              onTap: () async {
                                if (widget.isSeller) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditStoreProfilePage(profileData: _profile),
                                    ),
                                  );
                                } else {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditBuyerProfilePage(profileData: _profile),
                                    ),
                                  );
                                }
                                _fetchProfile();
                              },
                            ),
                          ]),
                          const SizedBox(height: 20),

                          // ─── Pengaturan ────────────────────────────────────
                          _sectionLabel('Pengaturan'),
                          const SizedBox(height: 8),
                          _menuCard([
                            if (widget.isSeller)
                              _menuTile(
                                icon: Icons.shopping_bag_rounded,
                                label: 'Kelola Produk',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider(
                                        create: (_) => MarketplaceBloc()..add(LoadSellerProducts()),
                                        child: const ManageProductsPage(),
                                      ),
                                    ),
                                  );
                                },
                              )
                            else
                              _menuTile(
                                icon: Icons.favorite_rounded,
                                label: 'Wishlist Kamu',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const WishlistPage()),
                                  );
                                },
                              ),
                          ]),
                          const SizedBox(height: 20),

                          // ─── Bantuan ───────────────────────────────────────
                          _sectionLabel('Bantuan'),
                          const SizedBox(height: 8),
                          _menuCard([
                            _menuTile(
                              icon: Icons.help_rounded,
                              label: 'Pusat Bantuan',
                              onTap: () {
                                BrawigoToast.showInfo(
                                  context,
                                  title: 'Pusat Bantuan',
                                  message: 'Layanan Pusat Bantuan akan segera hadir!',
                                );
                              },
                            ),
                            const Divider(height: 1, indent: 52, color: Color(0xFFF1F5F9)),
                            _menuTile(
                              icon: Icons.thumb_up_rounded,
                              label: 'Suka Brawigo? Nilai kami!',
                              onTap: () {
                                BrawigoToast.showSuccess(
                                  context,
                                  title: 'Terima Kasih!',
                                  message: 'Terima kasih atas penilaian dan dukunganmu! 🎉',
                                );
                              },
                            ),
                          ]),
                          const SizedBox(height: 16),

                          // ─── Hapus Akun ────────────────────────────────────
                          _menuCard([
                            _menuTile(
                              icon: Icons.delete_rounded,
                              iconColor: const Color(0xFFEF4444),
                              iconBgColor: const Color(0xFFFFEBEE),
                              label: 'Hapus Akun',
                              labelColor: _textDark,
                              showArrow: false,
                              onTap: _confirmDeleteAccount,
                            ),
                          ]),
                          const SizedBox(height: 24),

                          // ─── Keluar Button ─────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.logout_rounded, color: _primary, size: 20),
                              label: const Text(
                                'Keluar',
                                style: TextStyle(
                                  color: _primary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _primary, width: 1.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _confirmLogout,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3873B2), Color(0xFF1F4A7A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F4A7A).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // White circle avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                ? NetworkImage(_photoUrl!)
                : null,
            child: _photoUrl == null || _photoUrl!.isEmpty
                ? const Icon(Icons.person_rounded, size: 32, color: _primary)
                : null,
          ),
          const SizedBox(width: 14),

          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayName ?? 'Pengguna Brawigo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                if (_subtitle != null && _subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    _subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                if (_email != null && _email!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _email!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: _textDark,
        ),
      ),
    );
  }

  Widget _menuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = _primary,
    Color? iconBgColor,
    Color labelColor = _textDark,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBgColor ?? const Color(0xFFE6EDF8),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
            if (showArrow)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 22),
          ],
        ),
      ),
    );
  }
}
