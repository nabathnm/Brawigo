import 'package:brawigo/features/marketplace/presentation/pages/buyer_product_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:brawigo/core/utils/constants/brawigo_colors.dart';

class BuyerProductHorizontalList extends StatelessWidget {
  final List<Map<String, dynamic>> products;

  const BuyerProductHorizontalList({super.key, required this.products});

  String _getCategoryName(Map<String, dynamic> product) {
    final category = product['categories'];

    if (category is Map<String, dynamic>) {
      final name = category['name'];

      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString();
      }
    }

    return 'Tanpa Kategori';
  }

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('Belum ada produk', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final product = products[index];

            final imageUrl = product['thumbnail_url'] as String?;

            final name = product['product_name'] as String? ?? 'Tanpa Nama';

            final price = (product['price'] as num?)?.toString() ?? '0';

            final categoryName = _getCategoryName(product);

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BuyerProductDetailPage(product: product),
                  ),
                );
              },
              child: Container(
                width: 155,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              height: 145,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return _buildImagePlaceholder();
                              },
                            )
                          : _buildImagePlaceholder(),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: BrawigoColors.blue600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              categoryName,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Text(
                              'Rp $price',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: BrawigoColors.blue950,
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

  Widget _buildImagePlaceholder() {
    return Container(
      height: 145,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }
}
