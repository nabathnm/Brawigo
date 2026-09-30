import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'package:flutter/material.dart';

class CheckoutProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String productName;
  final num price;

  const CheckoutProductCard({
    super.key,
    required this.product,
    required this.productName,
    required this.price,
  });

  String _formatRupiah(num value) {
    final formatted = value.toInt().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = product['thumbnail_url'];

    return Container(
      decoration: BoxDecoration(
        color: Color(0Xffffffff),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/icons/marketplace/cart.png",
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Pesananmu',
                  style: TextStyle(
                    color: BrawigoColors.blue800,
                    fontWeight: .w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Divider(
              height: 1,
              color: const Color(0xff20395A).withValues(alpha: 0.25),
            ),

            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      thumbnailUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const ContainerPlaceholder();
                      },
                    ),
                  )
                else
                  const ContainerPlaceholder(),

                const SizedBox(width: 12),

                Expanded(
                  child: Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(
                              color: BrawigoColors.blue600,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatRupiah(price),
                            style: const TextStyle(
                              color: BrawigoColors.blue800,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          "1x",
                          style: TextStyle(
                            fontWeight: .w600,
                            color: BrawigoColors.blue800,
                            fontSize: 14,
                          ),
                        ),
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
  }
}

class ContainerPlaceholder extends StatelessWidget {
  const ContainerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
}
