import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchFilterData {
  final String? category;
  final double? minPrice;
  final double? maxPrice;

  const SearchFilterData({
    this.category,
    this.minPrice,
    this.maxPrice,
  });

  bool get isActive =>
      (category != null && category!.isNotEmpty) ||
      minPrice != null ||
      maxPrice != null;
}

class BuyerSearchFilterPage extends StatefulWidget {
  final SearchFilterData? initialFilter;

  const BuyerSearchFilterPage({
    super.key,
    this.initialFilter,
  });

  @override
  State<BuyerSearchFilterPage> createState() => _BuyerSearchFilterPageState();
}

class _BuyerSearchFilterPageState extends State<BuyerSearchFilterPage> {
  String? _selectedCategory;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  static const List<String> _fallbackCategories = [
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
  List<String> _categories = _fallbackCategories;
  bool _isLoadingCategories = true;

  final _currencyFormatter = NumberFormat.decimalPattern('id_ID');

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialFilter?.category;

    final minPrice = widget.initialFilter?.minPrice;
    final maxPrice = widget.initialFilter?.maxPrice;

    _minPriceController = TextEditingController(
      text: minPrice != null ? _currencyFormatter.format(minPrice.toInt()) : '',
    );
    _maxPriceController = TextEditingController(
      text: maxPrice != null ? _currencyFormatter.format(maxPrice.toInt()) : '',
    );
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await Supabase.instance.client
          .from('categories')
          .select('name')
          .order('name');
      final names = (res as List)
          .map((c) => c['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      if (names.isNotEmpty && mounted) {
        setState(() {
          _categories = names;
          _isLoadingCategories = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _formatControllerText(TextEditingController controller, String value) {
    final cleanStr = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanStr.isEmpty) {
      controller.text = '';
      return;
    }
    final numVal = int.tryParse(cleanStr);
    if (numVal != null) {
      final formatted = _currencyFormatter.format(numVal);
      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  double? _parsePrice(String text) {
    final cleanStr = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanStr.isEmpty) return null;
    return double.tryParse(cleanStr);
  }

  void _resetFilter() {
    setState(() {
      _selectedCategory = null;
      _minPriceController.clear();
      _maxPriceController.clear();
    });
    // Kembalikan filter kosong saat user menekan Reset Filter
    Navigator.pop(context, const SearchFilterData());
  }

  void _applyFilter() {
    final minPrice = _parsePrice(_minPriceController.text);
    final maxPrice = _parsePrice(_maxPriceController.text);

    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harga terendah tidak boleh lebih besar dari harga tertinggi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final result = SearchFilterData(
      category: _selectedCategory,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E3A8A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Filter Pencarian',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. KATEGORI
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedCategory = null; // deselect
                              } else {
                                _selectedCategory = cat;
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF5A94CF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF5A94CF)
                                    : const Color(0xFFCBD5E1),
                                width: 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF5A94CF).withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 28),

                    // 2. HARGA
                    const Text(
                      'Harga',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Harga Terendah
                        Expanded(
                          child: _buildPriceInput(
                            controller: _minPriceController,
                            hintText: 'Terendah',
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Harga Tertinggi
                        Expanded(
                          child: _buildPriceInput(
                            controller: _maxPriceController,
                            hintText: 'Tertinggi',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // 3. TOMBOL AKSI BAWAH (Reset Filter & Tampilkan Hasil)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Tombol Reset Filter
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetFilter,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF5A94CF),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Reset Filter',
                        style: TextStyle(
                          color: Color(0xFF5A94CF),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol Tampilkan Hasil
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A94CF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Tampilkan Hasil',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInput({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          const Text(
            'Rp',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (val) => _formatControllerText(controller, val),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF15243C),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

