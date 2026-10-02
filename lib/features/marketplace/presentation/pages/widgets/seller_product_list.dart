import 'package:flutter/material.dart';

import 'package:brawigo/features/marketplace/presentation/pages/widgets/seller_product_card.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/seller_product_filter_bar.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/seller_product_empty_state.dart';

class SellerProductList extends StatelessWidget {
  const SellerProductList({
    super.key,
    required this.products,
    required this.selectedFilter,
    required this.searchQuery,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> products;
  final SellerProductFilter selectedFilter;
  final String searchQuery;
  final ValueChanged<Map<String, dynamic>> onDelete;

  int _stockOf(Map<String, dynamic> product) =>
      (product['stock'] as num?)?.toInt() ?? 0;

  String _statusOf(Map<String, dynamic> product) =>
      product['status'] as String? ?? 'active';

  List<Map<String, dynamic>> get _filteredProducts {
    final byFilter = products.where((product) {
      final stock = _stockOf(product);
      final status = _statusOf(product);

      switch (selectedFilter) {
        case SellerProductFilter.all:
          return true;
        case SellerProductFilter.active:
          return stock > 0 && status != 'archived';
        case SellerProductFilter.outOfStock:
          return stock <= 0;
        case SellerProductFilter.archived:
          return status == 'archived';
      }
    });

    if (searchQuery.isEmpty) return byFilter.toList();

    return byFilter.where((product) {
      final name = (product['product_name'] as String? ?? '').toLowerCase();
      return name.contains(searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayedProducts = _filteredProducts;

    if (displayedProducts.isEmpty) {
      return const SellerProductEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: displayedProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final product = displayedProducts[index];

        return SellerProductCard(
          product: product,
          onDelete: () => onDelete(product),
        );
      },
    );
  }
}
