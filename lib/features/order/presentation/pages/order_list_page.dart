import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:brawigo/features/chat/presentation/pages/chat_room_page.dart';
import 'package:brawigo/features/order/presentation/pages/rating_page.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import 'order_detail_page.dart';

class OrderListPage extends StatefulWidget {
  final bool isSeller;
  const OrderListPage({super.key, this.isSeller = false});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  final _supabase = Supabase.instance.client;
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // Set ID order yang sudah dinilai oleh buyer
  Set<String> _reviewedOrderIds = {};

  // Map product_id -> category_name
  final Map<String, String> _productCategoryMap = {};

  // Filter State
  String? _selectedCategory;
  int? _selectedDateRangeDays; // 30, 90, or null
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String? _selectedStatusFilter; // 'Menunggu Konfirmasi', 'Diproses', 'Selesai', 'Dibatalkan'

  // Seller tab filter index
  int _sellerFilterIndex = 0;

  num _parseAmount(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val;
    if (val is String) {
      final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
      return num.tryParse(clean) ?? 0;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _fetchReviewedOrderIds();
  }

  void _loadOrders() {
    if (widget.isSeller) {
      context.read<OrderBloc>().add(LoadSellerOrders());
    } else {
      context.read<OrderBloc>().add(LoadBuyerOrders());
      _fetchReviewedOrderIds();
    }
  }

  Future<void> _fetchReviewedOrderIds() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final res = await _supabase
          .from('reviews')
          .select('order_id')
          .eq('reviewer_id', user.id);
      if (mounted) {
        setState(() {
          _reviewedOrderIds = (res as List).map((r) => r['order_id'].toString()).toSet();
        });
      }
    } catch (e) {
      debugPrint('Error fetching reviewed orders: $e');
    }
  }

  Future<void> _fetchProductCategories(List<Map<String, dynamic>> orders) async {
    final productIds = orders
        .map((o) => o['product_id']?.toString())
        .where((id) => id != null && id.isNotEmpty && !_productCategoryMap.containsKey(id))
        .toSet()
        .toList();

    if (productIds.isEmpty) return;

    try {
      final res = await _supabase
          .from('products')
          .select('id, category_id, categories(name)')
          .filter('id', 'in', productIds);

      for (final row in res as List) {
        final pId = row['id']?.toString();
        final catData = row['categories'];
        final catName = catData is Map ? catData['name']?.toString() : null;
        if (pId != null && catName != null) {
          _productCategoryMap[pId] = catName;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  bool get _hasActiveFilters {
    return _selectedCategory != null ||
        _selectedDateRangeDays != null ||
        _customStartDate != null ||
        _customEndDate != null ||
        _selectedStatusFilter != null;
  }

  List<Map<String, dynamic>> _filterOrders(List<Map<String, dynamic>> allOrders) {
    if (widget.isSeller) {
      if (_sellerFilterIndex == 0) return allOrders;
      return allOrders.where((order) {
        final status = (order['order_status'] ?? order['status'] ?? '').toString().toLowerCase();
        if (_sellerFilterIndex == 1) {
          return status != 'completed' && status != 'cancelled';
        } else if (_sellerFilterIndex == 2) {
          return status == 'completed';
        } else if (_sellerFilterIndex == 3) {
          return status == 'cancelled';
        }
        return true;
      }).toList();
    }

    // Buyer Filters
    return allOrders.where((order) {
      final status = (order['order_status'] ?? order['status'] ?? '').toString().toLowerCase();

      // 1. Status Filter
      if (_selectedStatusFilter != null) {
        if (_selectedStatusFilter == 'Menunggu Konfirmasi') {
          if (status != 'waiting_confirmation' && status != 'created' && status != 'pending') {
            return false;
          }
        } else if (_selectedStatusFilter == 'Diproses') {
          final isProcessing = status == 'confirmed' ||
              status == 'waiting_payment_courier' ||
              status == 'waiting_pickup' ||
              status == 'on_delivery' ||
              status == 'waiting_meetup';
          if (!isProcessing) return false;
        } else if (_selectedStatusFilter == 'Selesai') {
          if (status != 'completed') return false;
        } else if (_selectedStatusFilter == 'Dibatalkan') {
          if (status != 'cancelled') return false;
        }
      }

      // 2. Category Filter
      if (_selectedCategory != null) {
        final pId = order['product_id']?.toString();
        final cName = _productCategoryMap[pId] ?? '';
        final pName = order['product_name_snapshot']?.toString() ?? '';
        final matchesCat = cName.toLowerCase() == _selectedCategory!.toLowerCase() ||
            pName.toLowerCase().contains(_selectedCategory!.toLowerCase());
        if (!matchesCat) return false;
      }

      // 3. Date Filter
      final createdAtStr = order['created_at']?.toString();
      if (createdAtStr != null && createdAtStr.isNotEmpty) {
        final createdAt = DateTime.tryParse(createdAtStr)?.toLocal();
        if (createdAt != null) {
          final now = DateTime.now();
          if (_selectedDateRangeDays != null) {
            final startBoundary = now.subtract(Duration(days: _selectedDateRangeDays!));
            if (createdAt.isBefore(startBoundary)) return false;
          } else if (_customStartDate != null || _customEndDate != null) {
            if (_customStartDate != null) {
              final startOfDay = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
              if (createdAt.isBefore(startOfDay)) return false;
            }
            if (_customEndDate != null) {
              final endOfDay = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59);
              if (createdAt.isAfter(endOfDay)) return false;
            }
          }
        }
      }

      return true;
    }).toList();
  }

  // Pengelompokan status pill sesuai Gambar 3
  Map<String, dynamic> _getBuyerStatusConfig(String rawStatus) {
    final status = rawStatus.toLowerCase();
    if (status == 'completed') {
      return {
        'label': '• Selesai',
        'bg': const Color(0xFFDCFCE7),
        'text': const Color(0xFF16A34A),
        'category': 'completed',
      };
    } else if (status == 'cancelled') {
      return {
        'label': '• Dibatalkan',
        'bg': const Color(0xFFF1F5F9),
        'text': const Color(0xFF64748B),
        'category': 'cancelled',
      };
    } else if (status == 'waiting_confirmation' || status == 'created' || status == 'pending') {
      return {
        'label': '• Menunggu Konfirmasi',
        'bg': const Color(0xFFFEF3C7),
        'text': const Color(0xFFD97706),
        'category': 'waiting',
      };
    } else {
      // confirmed, waiting_payment_courier, waiting_pickup, on_delivery, waiting_meetup
      return {
        'label': '• Diproses',
        'bg': const Color(0xFFF3E8FF),
        'text': const Color(0xFF9333EA),
        'category': 'processing',
      };
    }
  }

  String _formatDisplayDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('d MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return '';
    }
  }

  Future<void> _openChatWithSeller(BuildContext context, Map<String, dynamic> order) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final buyerId = order['buyer_id']?.toString() ?? currentUserId;
    final sellerId = order['seller_id']?.toString() ?? '';
    if (sellerId.isEmpty || sellerId == currentUserId) return;

    String displayName = order['seller_name']?.toString() ?? '';
    if (displayName.isEmpty || displayName == 'Penjual Brawigo') {
      try {
        final profile = await _supabase
            .from('profiles')
            .select('full_name, username')
            .eq('id', sellerId)
            .maybeSingle();
        if (profile != null) {
          displayName = (profile['full_name']?.toString().isNotEmpty == true)
              ? profile['full_name']
              : profile['username']?.toString() ?? 'Penjual Brawigo';
        }
      } catch (_) {}
    }

    try {
      final existingConvs = await _supabase
          .from('conversations')
          .select('id')
          .or('and(buyer_id.eq.$buyerId,seller_id.eq.$sellerId),and(buyer_id.eq.$sellerId,seller_id.eq.$buyerId)')
          .limit(1);

      String conversationId;
      if ((existingConvs as List).isNotEmpty) {
        conversationId = existingConvs.first['id'];
      } else {
        try {
          final newConv = await _supabase.from('conversations').insert({
            'buyer_id': buyerId,
            'seller_id': sellerId,
            'product_id': order['product_id'],
          }).select('id').single();
          conversationId = newConv['id'];
        } on PostgrestException catch (e) {
          if (e.code == '23505') {
            final convList = await _supabase
                .from('conversations')
                .select('id')
                .or('and(buyer_id.eq.$buyerId,seller_id.eq.$sellerId),and(buyer_id.eq.$sellerId,seller_id.eq.$buyerId)')
                .limit(1);
            conversationId = convList.first['id'];
          } else {
            rethrow;
          }
        }
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomPage(
            conversationId: conversationId,
            otherUserName: displayName,
            otherUserId: sellerId,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to chat: $e');
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String? tempCategory = _selectedCategory;
        int? tempDateRange = _selectedDateRangeDays;
        DateTime? tempStartDate = _customStartDate;
        DateTime? tempEndDate = _customEndDate;
        String? tempStatus = _selectedStatusFilter;

        final categories = [
          'Alat Elektronik',
          'Perlengkapan Kuliah',
          'Buku & Alat Tulis',
          'Makanan & Minuman',
          'Perawatan Diri',
          'Fashion',
          'Hobi & Kreatif',
          'Perabotan Kos/Rumah',
          'Jasa',
          'Lainnya',
        ];

        final statuses = [
          'Menunggu Konfirmasi',
          'Diproses',
          'Selesai',
          'Dibatalkan',
        ];

        return StatefulBuilder(
          builder: (context, setModalState) {
            final dateFormat = DateFormat('dd/MM/yyyy');

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF15243C)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Filter Transaksi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15243C),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Section 1: Kategori
                          const Text(
                            'Kategori',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15243C),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            children: categories.map((cat) {
                              final isSelected = tempCategory == cat;
                              return InkWell(
                                onTap: () {
                                  setModalState(() {
                                    tempCategory = isSelected ? null : cat;
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF2B5F9E) : const Color(0xFFE2E8F0),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? const Color(0xFF2B5F9E) : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // Section 2: Tanggal Pembelian
                          const Text(
                            'Tanggal Pembelian',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15243C),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildChoiceChip(
                                label: '30 Hari Terakhir',
                                isSelected: tempDateRange == 30,
                                onTap: () {
                                  setModalState(() {
                                    if (tempDateRange == 30) {
                                      tempDateRange = null;
                                    } else {
                                      tempDateRange = 30;
                                      tempStartDate = null;
                                      tempEndDate = null;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildChoiceChip(
                                label: '90 Hari Terakhir',
                                isSelected: tempDateRange == 90,
                                onTap: () {
                                  setModalState(() {
                                    if (tempDateRange == 90) {
                                      tempDateRange = null;
                                    } else {
                                      tempDateRange = 90;
                                      tempStartDate = null;
                                      tempEndDate = null;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          const Text(
                            'Pilih Tanggal Sendiri',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: tempStartDate ?? DateTime.now(),
                                      firstDate: DateTime(2023),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        tempStartDate = picked;
                                        tempDateRange = null;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey.shade600),
                                        const SizedBox(width: 8),
                                        Text(
                                          tempStartDate != null ? dateFormat.format(tempStartDate!) : 'dd/mm/yyyy',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: tempStartDate != null ? const Color(0xFF15243C) : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: tempEndDate ?? DateTime.now(),
                                      firstDate: DateTime(2023),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        tempEndDate = picked;
                                        tempDateRange = null;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey.shade600),
                                        const SizedBox(width: 8),
                                        Text(
                                          tempEndDate != null ? dateFormat.format(tempEndDate!) : 'dd/mm/yyyy',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: tempEndDate != null ? const Color(0xFF15243C) : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Section 3: Status
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15243C),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            children: statuses.map((stat) {
                              final isSelected = tempStatus == stat;
                              return _buildChoiceChip(
                                label: stat,
                                isSelected: isSelected,
                                onTap: () {
                                  setModalState(() {
                                    tempStatus = isSelected ? null : stat;
                                  });
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2B5F9E),
                            side: const BorderSide(color: Color(0xFF2B5F9E)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            setModalState(() {
                              tempCategory = null;
                              tempDateRange = null;
                              tempStartDate = null;
                              tempEndDate = null;
                              tempStatus = null;
                            });
                          },
                          child: const Text('Reset Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2B5F9E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedCategory = tempCategory;
                              _selectedDateRangeDays = tempDateRange;
                              _customStartDate = tempStartDate;
                              _customEndDate = tempEndDate;
                              _selectedStatusFilter = tempStatus;
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text('Tampilkan Hasil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2B5F9E) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF2B5F9E) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: widget.isSeller
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                foregroundColor: const Color(0xFF15243C),
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                  statusBarBrightness: Brightness.light,
                ),
                title: const Text(
                  'Pesanan Masuk (Seller)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15243C),
                    fontSize: 18,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2B5F9E)),
                    onPressed: _loadOrders,
                    tooltip: 'Refresh Pesanan',
                  ),
                ],
              )
            : null,
        body: SafeArea(
          child: BlocBuilder<OrderBloc, OrderState>(
            builder: (context, state) {
              if (state is OrderLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2B5F9E)),
                );
              } else if (state is OrderError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 56),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          style: const TextStyle(color: Color(0xFF15243C), fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2B5F9E),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _loadOrders,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (state is OrdersLoaded) {
                final allOrders = state.orders;
                _fetchProductCategories(allOrders);
                final filteredOrders = _filterOrders(allOrders);

                if (widget.isSeller) {
                  return _buildSellerView(allOrders, filteredOrders);
                } else {
                  return _buildBuyerView(allOrders, filteredOrders);
                }
              }
              return const Center(child: Text('Memuat data pesanan...'));
            },
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // BUYER VIEW (Sesuai Gambar 3)
  // =========================================================================
  Widget _buildBuyerView(List<Map<String, dynamic>> allOrders, List<Map<String, dynamic>> filteredOrders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Khusus Buyer: "Riwayat Transaksi" + Button Filter
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Transaksi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15243C),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2B5F9E)),
                    onPressed: _loadOrders,
                    tooltip: 'Refresh Pesanan',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _showFilterModal,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _hasActiveFilters ? const Color(0xFF2B5F9E) : const Color(0xFFCBD5E1),
                      width: _hasActiveFilters ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: _hasActiveFilters ? const Color(0xFF2B5F9E) : const Color(0xFF475569),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _hasActiveFilters ? 'Filter Aktif' : 'Filter',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _hasActiveFilters ? const Color(0xFF2B5F9E) : const Color(0xFF475569),
                        ),
                      ),
                      if (_hasActiveFilters) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2B5F9E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Order List
        Expanded(
          child: filteredOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _hasActiveFilters ? 'Tidak ada transaksi sesuai filter' : 'Belum ada riwayat transaksi',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      if (_hasActiveFilters) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = null;
                              _selectedDateRangeDays = null;
                              _customStartDate = null;
                              _customEndDate = null;
                              _selectedStatusFilter = null;
                            });
                          },
                          child: const Text('Reset Filter', style: TextStyle(color: Color(0xFF2B5F9E), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _loadOrders();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: filteredOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildBuyerOrderCard(order);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBuyerOrderCard(Map<String, dynamic> order) {
    final orderId = order['id']?.toString() ?? '';
    final productName = order['product_name_snapshot'] ?? 'Produk Brawigo';
    final num totalAmount = _parseAmount(order['total_amount'] ?? order['product_price_snapshot']);
    final rawStatus = (order['order_status'] ?? order['status'] ?? 'created').toString();
    final statusCfg = _getBuyerStatusConfig(rawStatus);
    final createdAt = _formatDisplayDate(order['created_at']?.toString());
    final thumbnailUrl = order['thumbnail_url_snapshot'] as String?;

    final isReviewed = _reviewedOrderIds.contains(orderId);
    final statusCategory = statusCfg['category'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Date & Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                createdAt,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF15243C),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusCfg['bg'] as Color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusCfg['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusCfg['text'] as Color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Middle: Product Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                    ? Image.network(
                        thumbnailUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15243C),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currencyFormat.format(totalAmount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B5F9E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Bottom Action Buttons (Sesuai Gambar 3)
          // 1. Belum Selesai (waiting / processing): [Lihat Detail (Biru)] + [Kotak Chat]
          if (statusCategory == 'waiting' || statusCategory == 'processing') ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B5F9E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => OrderBloc(),
                              child: OrderDetailPage(orderId: orderId),
                            ),
                          ),
                        );
                        _loadOrders();
                      },
                      child: const Text('Lihat Detail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B5F9E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                    ),
                    onPressed: () => _openChatWithSeller(context, order),
                    child: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ]
          // 2. Selesai (completed):
          // Jika belum dinilai: [Lihat Detail (Outlined)] + [Nilai Pesanan (Biru)]
          // Jika sudah dinilai: [Lihat Detail (Biru Full)]
          else if (statusCategory == 'completed') ...[
            if (!isReviewed) ...[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2B5F9E),
                          side: const BorderSide(color: Color(0xFF2B5F9E)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider(
                              create: (_) => OrderBloc(),
                              child: OrderDetailPage(orderId: orderId),
                            ),
                            ),
                          );
                          _loadOrders();
                        },
                        child: const Text('Lihat Detail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B5F9E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final res = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RatingPage(order: order),
                            ),
                          );
                          if (res == true) {
                            _loadOrders();
                          }
                        },
                        child: const Text('Nilai Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                height: 40,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B5F9E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                              create: (_) => OrderBloc(),
                              child: OrderDetailPage(orderId: orderId),
                            ),
                      ),
                    );
                    _loadOrders();
                  },
                  child: const Text('Lihat Detail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ]
          // 3. Dibatalkan: [Lihat Detail (Biru Full)]
          else ...[
            SizedBox(
              height: 40,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B5F9E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                              create: (_) => OrderBloc(),
                              child: OrderDetailPage(orderId: orderId),
                            ),
                    ),
                  );
                  _loadOrders();
                },
                child: const Text('Lihat Detail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // SELLER VIEW
  // =========================================================================
  Widget _buildSellerView(List<Map<String, dynamic>> allOrders, List<Map<String, dynamic>> filteredOrders) {
    final int countAll = allOrders.length;
    final int countActive = allOrders.where((o) {
      final s = (o['order_status'] ?? o['status'] ?? '').toString().toLowerCase();
      return s != 'completed' && s != 'cancelled';
    }).length;
    final int countCompleted = allOrders.where((o) => (o['order_status'] ?? o['status'] ?? '').toString().toLowerCase() == 'completed').length;
    final int countCancelled = allOrders.where((o) => (o['order_status'] ?? o['status'] ?? '').toString().toLowerCase() == 'cancelled').length;

    final filterTabs = [
      'Semua ($countAll)',
      'Perlu Diproses ($countActive)',
      'Selesai ($countCompleted)',
      'Dibatalkan ($countCancelled)',
    ];

    return Column(
      children: [
        // Filter Pills Horizontal
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: filterTabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSelected = _sellerFilterIndex == index;
              return ChoiceChip(
                label: Text(
                  filterTabs[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : const Color(0xFF15243C),
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF2B5F9E),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF2B5F9E) : const Color(0xFFE2E8F0),
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _sellerFilterIndex = index);
                  }
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Order List
        Expanded(
          child: filteredOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada pesanan masuk',
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadOrders(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filteredOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final orderId = order['id']?.toString() ?? '';
                      final productName = order['product_name_snapshot'] ?? 'Produk Brawigo';
                      final num totalAmount = _parseAmount(order['total_amount'] ?? order['product_price_snapshot']);
                      final paymentMethod = order['payment_method']?.toString() ?? 'COD';
                      final rawStatus = (order['order_status'] ?? order['status'] ?? 'created').toString();
                      final statusCfg = _getBuyerStatusConfig(rawStatus);
                      final createdAt = _formatDisplayDate(order['created_at']?.toString());
                      final thumbnailUrl = order['thumbnail_url_snapshot'] as String?;

                      return InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider(
                              create: (_) => OrderBloc(),
                              child: OrderDetailPage(orderId: orderId),
                            ),
                            ),
                          );
                          _loadOrders();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    createdAt,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusCfg['bg'] as Color,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      statusCfg['label'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: statusCfg['text'] as Color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16, color: Color(0xFFF1F5F9)),
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                                        ? Image.network(
                                            thumbnailUrl,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                          )
                                        : _buildPlaceholder(),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          productName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF15243C)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _currencyFormat.format(totalAmount),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2B5F9E)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Metode: $paymentMethod',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: const Color(0xFFE2E8F0),
      child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF94A3B8), size: 28),
    );
  }
}
