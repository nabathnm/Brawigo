import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_event.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_state.dart';
import 'package:brawigo/features/marketplace/presentation/pages/update_product_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isPreview;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.isPreview = false,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final PageController _pageController = PageController();

  int _currentImageIndex = 0;
  bool _isDescriptionExpanded = false;

  String get _productId => widget.product['id']?.toString() ?? '';

  String get _productName =>
      widget.product['product_name']?.toString() ??
      widget.product['name']?.toString() ??
      'Tanpa nama';

  String get _categoryName =>
      widget.product['category_name']?.toString() ?? 'Alat Elektronik';

  String get _description =>
      widget.product['description']?.toString() ??
      'Tidak ada deskripsi produk.';

  String get _sellerId => widget.product['seller_id']?.toString() ?? '';

  String get _sellerName =>
      widget.product['seller_name']?.toString() ?? 'Penjual';

  String get _thumbnailUrl => widget.product['thumbnail_url']?.toString() ?? '';

  String _formatCurrency(dynamic amount) {
    final value = (amount as num?)?.toInt() ?? 0;
    final digits = value.toString();
    final result = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        result.write('.');
      }
      result.write(digits[i]);
    }

    return result.toString();
  }

  bool get _isSeller {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return currentUserId != null &&
        _sellerId == currentUserId &&
        !widget.isPreview;
  }

  @override
  void initState() {
    super.initState();

    if (!widget.isPreview && _productId.isNotEmpty) {
      context.read<MarketplaceBloc>().add(
        LoadProductImages(productId: _productId),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              context.read<MarketplaceBloc>().add(
                DeleteProduct(
                  id: _productId,
                  imageUrl: _thumbnailUrl.isEmpty ? null : _thumbnailUrl,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _editProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<MarketplaceBloc>(),
          child: UpdateProductPage(product: widget.product),
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    if (widget.isPreview) {
      return _buildImagePage([if (_thumbnailUrl.isNotEmpty) _thumbnailUrl]);
    }

    return BlocBuilder<MarketplaceBloc, MarketplaceState>(
      buildWhen: (previous, current) =>
          current is ProductImagesLoading ||
          current is ProductImagesLoaded ||
          current is ProductImagesError,
      builder: (context, state) {
        if (state is ProductImagesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ProductImagesError) {
          return _buildImageError();
        }

        if (state is ProductImagesLoaded) {
          final images = state.images.isNotEmpty
              ? state.images
              : [if (_thumbnailUrl.isNotEmpty) _thumbnailUrl];

          return _buildImagePage(images);
        }

        return _buildImagePage([if (_thumbnailUrl.isNotEmpty) _thumbnailUrl]);
      },
    );
  }

  Widget _buildImagePage(List<String> images) {
    if (images.isEmpty) {
      return _buildImageError();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (index) {
            setState(() => _currentImageIndex = index);
          },
          itemBuilder: (context, index) {
            return Image.network(
              images[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildImageError(),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '${_currentImageIndex + 1}/${images.length}',
              style: const TextStyle(
                color: Color(0xFF15243C),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image_outlined,
        size: 80,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _productName,
            style: const TextStyle(
              color: Color(0xFF2B5F9E),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ),
        if (_isSeller) ...[
          IconButton(
            tooltip: 'Edit produk',
            onPressed: _editProduct,
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF2B5F9E)),
          ),
          IconButton(
            tooltip: 'Hapus produk',
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ],
    );
  }

  Widget _buildProductInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _categoryName,
                  style: const TextStyle(
                    color: Color(0xFF15243C),
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                'Rp ${_formatCurrency(widget.product['price'])}',
                style: const TextStyle(
                  color: Color(0xFF3873B2),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE6EDF8),
            child: const Icon(Icons.person, color: Color(0xFF2B5F9E), size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sellerName,
                  style: const TextStyle(
                    color: Color(0xFF15243C),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Penjual',
                  style: TextStyle(color: Color(0xFF515151), fontSize: 12),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              // TODO: Navigasi ke halaman toko penjual.
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFF2B5F9E),
              foregroundColor: Colors.white,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Kunjungi Toko'),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deskripsi',
            style: TextStyle(
              color: Color(0xFF15243C),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _description,
            textAlign: TextAlign.justify,
            maxLines: _isDescriptionExpanded ? null : 4,
            overflow: _isDescriptionExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF15243C),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (_description.length > 150)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isDescriptionExpanded = !_isDescriptionExpanded;
                  });
                },
                child: Text(
                  _isDescriptionExpanded
                      ? 'Lihat Lebih Sedikit'
                      : 'Lihat Selengkapnya',
                  style: const TextStyle(
                    color: Color(0xFF2B5F9E),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    if (widget.isPreview || _isSeller) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              // TODO: Hubungkan ke alur pembelian.
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B5F9E),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Beli Produk',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MarketplaceBloc, MarketplaceState>(
      listenWhen: (previous, current) =>
          current is MarketplaceDeleteSuccess || current is MarketplaceError,
      listener: (context, state) {
        if (state is MarketplaceDeleteSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));

          Navigator.of(context).pop();
        } else if (state is MarketplaceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F7FC),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SizedBox(
                height: 300,
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildImageArea()),
                    Positioned(
                      top: 12,
                      left: 16,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _buildProductInfo(),
                    const SizedBox(height: 12),
                    _buildSellerInfo(),
                    const SizedBox(height: 12),
                    _buildDescription(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomButton(),
      ),
    );
  }
}
