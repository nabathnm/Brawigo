import 'dart:async';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'buyer_product_detail_page.dart';
import 'buyer_search_page.dart';

class MarketplaceBuyerPage extends StatefulWidget {
  const MarketplaceBuyerPage({super.key});

  @override
  State<MarketplaceBuyerPage> createState() => _MarketplaceBuyerPageState();
}

class _MarketplaceBuyerPageState extends State<MarketplaceBuyerPage> {
  final PageController _pageController = PageController();
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;

  late final List<Map<String, String>> _dummyProductsTerbaru;
  late final List<Map<String, String>> _dummyProductsPopuler;

  @override
  void initState() {
    super.initState();

    _dummyProductsTerbaru = [
      {
        'name': 'Rice Cooker Mikoya',
        'category': 'Alat Elektronik',
        'price': 'Rp 200.000',
      },
      {
        'name': 'Hair Dryer Philips',
        'category': 'Alat Elektronik',
        'price': 'Rp 500.000',
      },
      {
        'name': 'Kipas Angin Cosmos',
        'category': 'Alat Elektronik',
        'price': 'Rp 150.000',
      },
    ];

    _dummyProductsPopuler = [
      {
        'name': 'Rice Cooker Mikoya',
        'category': 'Alat Elektronik',
        'price': 'Rp 200.000',
      },
      {
        'name': 'Hair Dryer Philips',
        'category': 'Alat Elektronik',
        'price': 'Rp 500.000',
      },
      {
        'name': 'Kipas Angin Cosmos',
        'category': 'Alat Elektronik',
        'price': 'Rp 150.000',
      },
    ];

    _carouselTimer = Timer.periodic(const Duration(seconds: 7), (Timer timer) {
      if (_currentCarouselIndex < 2) {
        _currentCarouselIndex++;
      } else {
        _currentCarouselIndex = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentCarouselIndex,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrawigoColors.blue100, 
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildSearchBar(),
              _buildCarousel(),
              _buildSectionTitle('Produk Terbaru'),
              _buildHorizontalProductList(_dummyProductsTerbaru),
              _buildSectionTitle('Produk Populer'),
              _buildHorizontalProductList(_dummyProductsPopuler),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: BrawigoColors.blueNormalActive,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Selamat Datang,",
                    style: TextStyle(fontSize: 12, color: Color(0xFF4A5568)),
                  ),
                  Text(
                    "Hassan Nashrallah",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: BrawigoColors.blue950, 
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'seller') {
                  context.go('/seller');
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              offset: const Offset(0, 40),
              color: Colors.white,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text(
                      "Buyer",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            BrawigoColors.blue950, 
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: BrawigoColors.blue950,
                    ), 
                  ],
                ),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'seller',
                  child: Text(
                    'Seller',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: TextField(
          readOnly: true, 
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BuyerSearchPage()),
            );
          },
          decoration: const InputDecoration(
            hintText: 'Cari produk',
            hintStyle: TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Color(0xFFA0AEC0),
              size: 22,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return Column(
      children: [
        Container(
          height: 180,
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse, 
                PointerDeviceKind.trackpad,
              },
            ),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              },
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        BrawigoColors.blue100,
                        BrawigoColors.blue200,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                            
                              child:  Image.asset(
                                'assets/images/logo_brawigo.png', 
                                width:48, 
                                height: 48,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              "Say Hello to Brawigo!",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: BrawigoColors
                                    .blue950, 
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Campus marketplace for everything you need.",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: BrawigoColors
                                    .blue800, 
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Positioned(
                        right: 16,
                        bottom: 30,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: BrawigoColors.blue950,
                          size: 24,
                        ), 
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            bool isActive = _currentCarouselIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: isActive ? 20 : 6,
              decoration: BoxDecoration(
                color: isActive
                    ? BrawigoColors.blue900
                    : BrawigoColors.blue300,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: BrawigoColors.blue950,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: BrawigoColors.blue950,
            size: 22,
          ), 
        ],
      ),
    );
  }

  Widget _buildHorizontalProductList(List<Map<String, String>> products) {
    return SizedBox(
      height: 250,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind
                .mouse, 
            PointerDeviceKind.trackpad,
          },
        ),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          separatorBuilder: (context, index) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final product = products[index];
            return GestureDetector(
              onTap: () {
                // Navigasi ke halaman detail saat diklik
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BuyerProductDetailPage(product: product),
                  ),
                );
              },
              child: Container(
                width: 155,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: Image.asset(
                      'assets/images/ricecooker.png',
                      height: 145,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 145,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name']!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: BrawigoColors
                                  .blue600, 
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product['category']!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            product['price']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: BrawigoColors
                                  .blue950, 
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Beranda',
                isActive: true,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_rounded,
                label: 'Pesan',
                isActive: false,
              ),
              _buildNavItem(
                icon: Icons.shopping_cart_rounded,
                label: 'Order',
                isActive: false,
              ),
              _buildNavItem(
                icon: Icons.account_circle_rounded,
                label: 'Profil',
                isActive: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final Color color = isActive
        ? BrawigoColors.blue600
        : const Color(0xFFB0BAC3); 
    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
