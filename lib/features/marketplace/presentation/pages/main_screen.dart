import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/pages/marketplace_buyer_page.dart';
import 'package:brawigo/features/marketplace/presentation/pages/marketplace_seller_page.dart';
import 'package:brawigo/features/marketplace/presentation/pages/add_product_page.dart';
import 'package:brawigo/features/marketplace/presentation/pages/order_page.dart';
import 'package:brawigo/features/profile/presentation/pages/profile_page.dart';
import 'package:brawigo/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:brawigo/features/auth/presentation/blocs/auth_state.dart';
import 'package:brawigo/features/auth/presentation/pages/login_page.dart';

class MainScreen extends StatefulWidget {
  final String role; // 'buyer' atau 'seller'

  const MainScreen({super.key, required this.role});

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
    _isSeller = widget.role.toLowerCase().trim() == 'seller';
    _pages = [
      _isSeller ? const MarketPlaceSellerPage() : const MarketPlaceBuyerPage(),
      const Scaffold(
        backgroundColor: Color(0xFFEAF0F6),
        body: Center(
          child: Text(
            "Halaman Pesan\n(Segera Hadir)",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6A7A8A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      const SizedBox(), // Placeholder untuk tombol tengah (+)
      const OrderPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial || state is AuthFailure) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFC8DAEF), // Stop 0%
                Color(0xFFE6EDF8), // Stop 20%
                Color(0xFFFAFAFA), // Stop 100%
              ],
              stops: [0.0, 0.2, 1.0],
            ),
          ),
          child: _pages[_currentIndex],
        ),
        bottomNavigationBar: Container(
          height: 106,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E2D3D).withAlpha(18),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 30),
              child: Row(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(
                    icon: Image.asset(
                      _currentIndex == 0
                          ? 'assets/images/navbar/beranda_active.png'
                          : 'assets/images/navbar/beranda.png',
                      width: 24,
                      height: 24,
                    ),
                    label: 'Beranda',
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Image.asset(
                      _currentIndex == 1
                          ? 'assets/images/navbar/pesan_active.png'
                          : 'assets/images/navbar/pesan.png',
                      width: 24,
                      height: 24,
                    ),
                    label: 'Pesan',
                    index: 1,
                  ),
                  _buildAddButton(context),
                  _buildNavItem(
                    icon: Image.asset(
                      _currentIndex == 3
                          ? 'assets/images/navbar/order_active.png'
                          : 'assets/images/navbar/order.png',
                      width: 24,
                      height: 24,
                    ),
                    label: 'Order',
                    index: 3,
                  ),
                  _buildNavItem(
                    icon: Image.asset(
                      _currentIndex == 4
                          ? 'assets/images/navbar/profil_active.png'
                          : 'assets/images/navbar/profil.png',
                      width: 24,
                      height: 24,
                    ),
                    label: 'Profil',
                    index: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required Widget icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? BrawigoColors.primary500
        : BrawigoColors.blueLightActive;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
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
            const SnackBar(
              content: Text("Hanya akun Seller yang dapat menambah produk."),
            ),
          );
        }
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: BrawigoColors.primary500,
          shape: BoxShape.circle,
        ),
        child: Image.asset("assets/images/navbar/tambah_produk.png"),
      ),
    );
  }
}
