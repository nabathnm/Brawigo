class ProductPriceFormatter {
  ProductPriceFormatter._();

  /// Format harga ke format Indonesia, misalnya `Rp 300.000`.
  /// Menerima angka mentah maupun string yang sudah diformat.
  static String format(dynamic amount) {
    if (amount == null) return 'Rp 0';

    if (amount is String) {
      final trimmed = amount.trim();
      if (trimmed.toLowerCase().startsWith('rp')) return trimmed;

      // Mendukung string angka biasa maupun angka dengan pemisah ribuan.
      final parsed = double.tryParse(
        trimmed.replaceAll('.', '').replaceAll(',', ''),
      );
      if (parsed == null) return 'Rp 0';
      return _formatInteger(parsed.toInt());
    }

    if (amount is num) return _formatInteger(amount.toInt());
    return 'Rp 0';
  }

  static String _formatInteger(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp $buffer';
  }
}
