import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/pages/marketplace_buyer_page.dart';
import 'package:brawigo/features/marketplace/presentation/pages/marketplace_seller_page.dart';
import 'package:brawigo/features/marketplace/presentation/pages/add_product_page.dart';
import 'package:brawigo/features/profile/presentation/pages/profile_page.dart';
import 'package:brawigo/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:brawigo/features/auth/presentation/blocs/auth_state.dart';
import 'package:brawigo/features/auth/presentation/pages/login_page.dart';

class MainScreen extends StatefulWidget {
  final bool isSeller;
  const MainScreen({super.key, this.isSeller = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  late final bool _isSeller;

  @override
  void initState() {
    super.initState();
    _isSeller = widget.isSeller;
    _pages = [
      _isSeller ? const MarketPlaceSellerPage() : const MarketplaceBuyerPage(),
      const Scaffold(
        backgroundColor: Color(0xFFEAF0F6),
        body: Center(
          child: Text(
            "Halaman Pesan\n(Segera Hadir)",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFF6A7A8A), fontWeight: FontWeight.w500),
          ),
        ),
      ),
      const SizedBox(), // Placeholder untuk tombol tengah (+)
      const Scaffold(
        backgroundColor: Color(0xFFEAF0F6),
        body: Center(
          child: Text(
            "Halaman Order\n(Segera Hadir)",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFF6A7A8A), fontWeight: FontWeight.w500),
          ),
        ),
      ),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial || state is AuthError) {
          // Jika logout sukses (atau error token), kembalikan ke LoginPage
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF0F6),
        body: _pages[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(icon: Icons.home_rounded, label: 'Beranda', index: 0),
                  _buildNavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Pesan', index: 1),
                  _buildAddButton(context),
                  _buildNavItem(icon: Icons.shopping_cart_outlined, label: 'Order', index: 3),
                  _buildNavItem(icon: Icons.person_outline_rounded, label: 'Profil', index: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFF2E6399) : const Color(0xFF90A4AE);

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isSeller) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Hanya akun Seller yang dapat menambah produk.")),
          );
        }
      },
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFF2E6399),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E6399).withAlpha(80),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

