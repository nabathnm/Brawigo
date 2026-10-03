import 'dart:async';

import 'package:brawigo/features/marketplace/presentation/pages/widgets/buyer_carousel.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/buyer_header.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/buyer_product_horizontal_list.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/buyer_search_bar.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/marketplace_section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import '../bloc/marketplace_bloc.dart';
import '../bloc/marketplace_state.dart';

class MarketplaceBuyerPage extends StatefulWidget {
  final bool hideBottomNav;

  const MarketplaceBuyerPage({super.key, this.hideBottomNav = false});

  @override
  State<MarketplaceBuyerPage> createState() => _MarketplaceBuyerPageState();
}

class _MarketplaceBuyerPageState extends State<MarketplaceBuyerPage> {
  final PageController _pageController = PageController();

  Timer? _carouselTimer;

  int _currentCarouselIndex = 0;

  String _displayName = 'Pengguna';
  String? _photoUrl;

  @override
  void initState() {
    super.initState();

    _loadUserProfile();
    _startCarousel();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted) return;

      final nextIndex = (_currentCarouselIndex + 1) % 3;

      setState(() {
        _currentCarouselIndex = nextIndex;
      });

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      final response = await supabase
          .from('profiles')
          .select('full_name, username, profile_photo_url')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted || response == null) return;

      final username = response['username']?.toString().trim();

      final fullName = response['full_name']?.toString().trim();

      final photo = response['profile_photo_url']?.toString().trim();

      String displayName = 'Pengguna';

      if (username != null && username.isNotEmpty && username != '-') {
        displayName = username;
      } else if (fullName != null && fullName.isNotEmpty) {
        displayName = fullName;
      } else {
        displayName = user.email?.split('@').first ?? 'Pengguna';
      }

      setState(() {
        _displayName = displayName;
        _photoUrl = photo;
      });
    } catch (_) {
      // Profile gagal dimuat tidak perlu
      // menghentikan halaman marketplace.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrawigoColors.blue100,
      body: SafeArea(
        child: BlocBuilder<MarketplaceBloc, MarketplaceState>(
          builder: (context, state) {
            final products = state is MarketplaceLoaded
                ? state.products
                : <Map<String, dynamic>>[];

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BuyerHeader(displayName: _displayName, photoUrl: _photoUrl),

                  const BuyerSearchBar(),

                  BuyerCarousel(
                    pageController: _pageController,
                    currentIndex: _currentCarouselIndex,
                    onPageChanged: (index) {
                      setState(() {
                        _currentCarouselIndex = index;
                      });
                    },
                  ),

                  const MarketplaceSectionTitle(title: 'Produk Terbaru'),

                  _buildProductContent(state, products),

                  const MarketplaceSectionTitle(title: 'Produk Populer'),

                  _buildProductContent(state, products),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductContent(
    MarketplaceState state,
    List<Map<String, dynamic>> products,
  ) {
    if (state is MarketplaceLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is MarketplaceError) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    return BuyerProductHorizontalList(products: products);
  }
}
