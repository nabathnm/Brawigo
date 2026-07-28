import 'package:flutter/material.dart';
import 'package:brawigo/features/marketplace/presentation/pages/product_detail_page.dart';
import 'package:brawigo/features/marketplace/presentation/pages/update_product_page.dart';

class SellerProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onDelete;

  const SellerProductCard({
    super.key,
    required this.product,
    required this.onDelete,
  });

  String _formatCurrency(dynamic amount) {
    final int value = (amount as num?)?.toInt() ?? 0;
    String valStr = value.toString();
    String result = '';
    int count = 0;
    for (int i = valStr.length - 1; i >= 0; i--) {
      if (count != 0 && count % 3 == 0) {
        result = '.$result';
      }
      result = valStr[i] + result;
      count++;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = product['thumbnail_url'] as String?;
    final String name = product['product_name'] as String? ?? 'Tanpa Nama';
    final dynamic priceVal = product['price'] ?? 0;
    final String formattedPrice = _formatCurrency(priceVal);
    final int stock = (product['stock'] as num?)?.toInt() ?? 0;
    final String status = product['status'] as String? ?? 'active';
    final String categoryName =
        product['category_name'] as String? ?? 'Alat Elektronik';

    // Atur Badge Status sesuai stok/status
    String badgeText = 'Aktif';
    Color badgeBg = const Color(0xFFE5F9EB);
    Color badgeColor = const Color(0xFF23B259);

    if (stock <= 0) {
      badgeText = 'Habis';
      badgeBg = const Color(0xFFFFECEE);
      badgeColor = const Color(0xFFFF4D4F);
    } else if (status == 'archived') {
      badgeText = 'Arsip';
      badgeBg = const Color(0xFFE6F0FF);
      badgeColor = const Color(0xFF1890FF);
    }

    return Container(
      height: 148,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDADADA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bagian Atas: Gambar + Detail Produk
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 91,
                    height: 82,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(color: badgeColor, fontSize: 12),
                      ),
                    ),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4A79),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      categoryName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6A7A8A),
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Rp $formattedPrice",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D4A79),
                          ),
                        ),
                        Text(
                          "Stok: $stock",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF556575),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Garis Pemisah & Tombol Aksi (Edit, Detail, Hapus)
          const Divider(height: 1, thickness: 1, color: Color(0xFFEFF3F7)),
          SizedBox(
            height: 36,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpdateProductPage(product: product),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF007BFF),
                          size: 10,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Edit",
                          style: TextStyle(
                            color: Color(0xFF007BFF),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 26, color: const Color(0xFFEFF3F7)),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailPage(product: product),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          color: Color(0xFF6A7A8A),
                          size: 10,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Detail",
                          style: TextStyle(
                            color: Color(0xFF6A7A8A),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 26, color: const Color(0xFFEFF3F7)),
                Expanded(
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(20),
                    ),
                    onTap: onDelete,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFFF4D4F),
                          size: 10,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Hapus",
                          style: TextStyle(
                            color: Color(0xFFFF4D4F),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: const Color(0xFFEBF0F5),
      child: const Icon(
        Icons.image_outlined,
        size: 40,
        color: Color(0xFF90A4AE),
      ),
    );
  }
}
