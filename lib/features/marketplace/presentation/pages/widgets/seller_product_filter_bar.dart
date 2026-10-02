import 'package:flutter/material.dart';

enum SellerProductFilter { all, active, outOfStock, archived }

class SellerProductFilterBar extends StatelessWidget {
  const SellerProductFilterBar({
    super.key,
    required this.products,
    required this.selectedFilter,
    required this.onSelected,
  });

  final List<Map<String, dynamic>> products;
  final SellerProductFilter selectedFilter;
  final ValueChanged<SellerProductFilter> onSelected;

  int _stockOf(Map<String, dynamic> product) =>
      (product['stock'] as num?)?.toInt() ?? 0;

  String _statusOf(Map<String, dynamic> product) =>
      product['status'] as String? ?? 'active';

  int get _activeCount => products.where((product) {
    return _stockOf(product) > 0 && _statusOf(product) != 'archived';
  }).length;

  int get _outOfStockCount =>
      products.where((product) => _stockOf(product) <= 0).length;

  int get _archivedCount =>
      products.where((product) => _statusOf(product) == 'archived').length;

  @override
  Widget build(BuildContext context) {
    final filters = <({SellerProductFilter value, String label})>[
      (value: SellerProductFilter.all, label: 'Semua (${products.length})'),
      (value: SellerProductFilter.active, label: 'Aktif ($_activeCount)'),
      (
        value: SellerProductFilter.outOfStock,
        label: 'Habis ($_outOfStockCount)',
      ),
      (value: SellerProductFilter.archived, label: 'Arsip ($_archivedCount)'),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter.value;

          return GestureDetector(
            onTap: () => onSelected(filter.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF6097D0), Color(0xFF244C80)],
                        stops: [0, 1],
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? null
                    : Border.all(color: const Color(0xFFD3DFE8), width: 1),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF244C80).withAlpha(60),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                filter.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF4A5D70),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
