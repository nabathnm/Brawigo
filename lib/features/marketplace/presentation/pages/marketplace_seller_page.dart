import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_event.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_state.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/custom_search.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/header.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/delete_product_dialog.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/seller_product_filter_bar.dart';
import 'package:brawigo/features/marketplace/presentation/pages/widgets/seller_product_list.dart';

class MarketPlaceSellerPage extends StatefulWidget {
  const MarketPlaceSellerPage({super.key});

  @override
  State<MarketPlaceSellerPage> createState() => _MarketPlaceSellerPageState();
}

class _MarketPlaceSellerPageState extends State<MarketPlaceSellerPage> {
  final TextEditingController _searchController = TextEditingController();

  SellerProductFilter _selectedFilter = SellerProductFilter.all;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(Map<String, dynamic> product) {
    DeleteProductDialog.show(
      context: context,
      product: product,
      onConfirm: (productId) {
        context.read<MarketplaceBloc>().add(DeleteProduct(id: productId));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Header(onRoleSwitch: () => context.go('/buyer')),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomSearch(
                controller: _searchController,
                hintText: 'Cari ..',
                onChanged: (value) {
                  setState(() => _searchQuery = value.trim().toLowerCase());
                },
                onFilterPressed: () {},
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocListener<MarketplaceBloc, MarketplaceState>(
                listener: (context, state) {
                  if (state is MarketplaceDeleteSuccess) {
                    _showSnackBar(
                      context,
                      state.message,
                      backgroundColor: Colors.green,
                    );
                  } else if (state is MarketplaceError) {
                    _showSnackBar(
                      context,
                      state.message,
                      backgroundColor: Colors.red,
                    );
                  }
                },
                child: BlocBuilder<MarketplaceBloc, MarketplaceState>(
                  builder: (context, state) {
                    if (state is MarketplaceLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2E6399),
                        ),
                      );
                    }

                    if (state is MarketplaceError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Error: ${state.message}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (state is MarketplaceLoaded) {
                      return _buildLoadedContent(state.products);
                    }

                    return const Center(
                      child: Text(
                        'Memuat data...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedContent(List<Map<String, dynamic>> products) {
    return Column(
      children: [
        SellerProductFilterBar(
          products: products,
          selectedFilter: _selectedFilter,
          onSelected: (filter) {
            setState(() => _selectedFilter = filter);
          },
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Produk Saya',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D4A79),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SellerProductList(
            products: products,
            selectedFilter: _selectedFilter,
            searchQuery: _searchQuery,
            onDelete: _confirmDelete,
          ),
        ),
      ],
    );
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
  }
}
