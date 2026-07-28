import 'package:flutter/material.dart';
import 'package:brawigo/features/marketplace/presentation/pages/order_detail_page.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  // 0: Pendapatan, 1: Orderan, 2: Riwayat
  int _selectedMainTab = 1;
  // 0: QRIS, 1: Transfer, 2: COD
  int _selectedSubTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF2F7),
      body: Column(
        children: [
          _buildHeader(),
          if (_selectedMainTab != 0) _buildSubTabHeader(),
          Expanded(
            child: _selectedMainTab == 0
                ? _buildPendapatanView()
                : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF244C80),
            Color(0xFF1B3D68),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Row
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.shopping_cart_rounded,
                        color: Color(0xFF1D3B5E),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              // Main Tab Selector Pill
              Container(
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF102A45),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildMainTabButton('Pendapatan', 0),
                    _buildMainTabButton('Orderan', 1),
                    _buildMainTabButton('Riwayat', 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainTabButton(String title, int index) {
    final isSelected = _selectedMainTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMainTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1E3A5F) : Colors.white70,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubTabHeader() {
    final subTabs = ['QRIS', 'Transfer', 'COD'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(subTabs.length, (index) {
          final isSelected = _selectedSubTab == index;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedSubTab = index;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      subTabs[index],
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF1890FF)
                            : const Color(0xFF8C9AA8),
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 3,
                    width: isSelected ? 64 : 0,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1890FF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOrdersList() {
    List<_OrderModel> orders = [];

    if (_selectedMainTab == 1) {
      // ORDERAN TAB
      if (_selectedSubTab == 0) {
        // QRIS (3 items like reference screen 1)
        orders = List.generate(
          3,
          (i) => _OrderModel(
            methodText: 'QRIS',
            methodColor: const Color(0xFF2E6399),
            price: 'Rp 200.000',
            productTitle: 'Magic Com Biru',
            buyerInfo: 'dari Hassan Nasrullah | ID20346-218',
            bannerText: 'Bukti Pembayaran Menunggu Verifikasi',
            bannerBgColor: const Color(0xFFDCEBFA),
            bannerTextColor: const Color(0xFF2A649B),
            bannerIcon: Icons.visibility_outlined,
          ),
        );
      } else if (_selectedSubTab == 1) {
        // Transfer (2 items like reference screen 2)
        orders = List.generate(
          2,
          (i) => _OrderModel(
            methodText: 'Transfer',
            methodColor: const Color(0xFF2E7D32),
            price: 'Rp 200.000',
            productTitle: 'Magic Com Biru',
            buyerInfo: 'dari Hassan Nasrullah | ID20346-218',
            bannerText: 'Bukti Pembayaran Menunggu Verifikasi',
            bannerBgColor: const Color(0xFFDCFCE7),
            bannerTextColor: const Color(0xFF2E7D32),
            bannerIcon: Icons.visibility_outlined,
          ),
        );
      } else {
        // COD (1 item like reference screen 3)
        orders = [
          _OrderModel(
            methodText: 'COD',
            methodColor: const Color(0xFFD97706),
            price: 'Rp 200.000',
            productTitle: 'Magic Com Biru',
            buyerInfo: 'dari Hassan Nasrullah | ID20346-218',
            bannerText: 'Pesanan COD Menunggu Konfirmasi',
            bannerBgColor: const Color(0xFFFEF3C7),
            bannerTextColor: const Color(0xFFB45309),
            bannerIcon: Icons.visibility_outlined,
          ),
        ];
      }
    } else if (_selectedMainTab == 2) {
      // RIWAYAT TAB (Completed Orders like reference screen 4)
      orders = List.generate(
        3,
        (i) => _OrderModel(
          methodText: 'Selesai',
          methodColor: const Color(0xFF64748B),
          price: 'Rp 200.000',
          productTitle: 'Magic Com Biru',
          buyerInfo: 'dari Hassan Nasrullah | ID20346-218',
        ),
      );
    }

    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada pesanan',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index]);
      },
    );
  }

  Widget _buildOrderCard(_OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E2D3D).withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailPage(
                  paymentMethod: order.methodText,
                  productTitle: order.productTitle,
                  price: order.price,
                ),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Card Header Area
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image Box
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6EFF8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFD3DFEA),
                          width: 0.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1544816155-12df9643f363?q=80&w=300&auto=format&fit=crop',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.kitchen_rounded,
                              size: 36,
                              color: Color(0xFF4A6884),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order.methodText,
                                style: TextStyle(
                                  color: order.methodColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                order.price,
                                style: const TextStyle(
                                  color: Color(0xFF1B3B60),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.productTitle,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.buyerInfo,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Card Bottom Banner (If applicable)
              if (order.bannerText != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: order.bannerBgColor,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        order.bannerIcon ?? Icons.info_outline,
                        size: 18,
                        color: order.bannerTextColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.bannerText!,
                          style: TextStyle(
                            color: order.bannerTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendapatanView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF244C80), Color(0xFF153358)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF244C80).withAlpha(60),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Pendapatan Bersih',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rp 600.000',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF86EFAC),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '3 Pesanan Selesai',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '+15% bulan ini',
                        style: TextStyle(
                          color: Color(0xFF86EFAC),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Transaksi Terakhir',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          // Sample Transaction History
          ...List.generate(
            3,
            (i) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_downward_rounded,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Magic Com Biru',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '28 Jul 2026 • COD',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    '+ Rp 200.000',
                    style: TextStyle(
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderModel {
  final String methodText;
  final Color methodColor;
  final String price;
  final String productTitle;
  final String buyerInfo;
  final String? bannerText;
  final Color? bannerBgColor;
  final Color? bannerTextColor;
  final IconData? bannerIcon;

  _OrderModel({
    required this.methodText,
    required this.methodColor,
    required this.price,
    required this.productTitle,
    required this.buyerInfo,
    this.bannerText,
    this.bannerBgColor,
    this.bannerTextColor,
    this.bannerIcon,
  });
}
