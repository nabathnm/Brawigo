import 'package:flutter/material.dart';

class OrderFilterTabs extends StatelessWidget {
  final Map<String, int> counts;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const OrderFilterTabs({
    super.key,
    required this.counts,
    required this.selectedIndex,
    required this.onSelected,
  });

  static String statusOf(Map<String, dynamic> order) =>
      (order['order_status'] ?? order['status'] ?? '')
          .toString()
          .toLowerCase();

  static Map<String, int> countStatuses(List<Map<String, dynamic>> orders) {
    return {
      'all': orders.length,
      'pending': orders.where((o) {
        final status = statusOf(o);
        return status == 'created' || status == 'pending';
      }).length,
      'confirmed': orders.where((o) => statusOf(o) == 'confirmed').length,
      'completed': orders.where((o) => statusOf(o) == 'completed').length,
      'cancelled': orders.where((o) => statusOf(o) == 'cancelled').length,
    };
  }

  static List<Map<String, dynamic>> filterOrders(
    List<Map<String, dynamic>> orders,
    int selectedIndex,
  ) {
    if (selectedIndex == 0) return orders;

    return orders.where((order) {
      final status = statusOf(order);
      switch (selectedIndex) {
        case 1:
          return status == 'created' || status == 'pending';
        case 2:
          return status == 'confirmed';
        case 3:
          return status == 'completed';
        case 4:
          return status == 'cancelled';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      'Semua (${counts['all'] ?? 0})',
      'Perlu Diproses (${counts['pending'] ?? 0})',
      'Dikonfirmasi (${counts['confirmed'] ?? 0})',
      'Selesai (${counts['completed'] ?? 0})',
      'Dibatalkan (${counts['cancelled'] ?? 0})',
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF2B5F9E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF2B5F9E)
                      : const Color(0xFFCBD5E1),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2B5F9E).withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF475569),
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
