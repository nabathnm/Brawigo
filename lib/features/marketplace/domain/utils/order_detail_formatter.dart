import 'package:intl/intl.dart';

class OrderDetailFormatter {
  OrderDetailFormatter._();

  static final currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String date(String? value) {
    if (value == null || value.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(value).toLocal();
      return '${DateFormat('EEEE, d MMMM yyyy - HH:mm', 'id_ID').format(dateTime)} WIB';
    } catch (_) {
      return value;
    }
  }
}
