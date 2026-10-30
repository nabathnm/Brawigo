class PaymentMethod {
  final String title;
  final String description;

  const PaymentMethod({required this.title, required this.description});
}

const paymentMethods = [
  PaymentMethod(title: 'QRIS', description: 'Bayar melalui QRIS Penjual.'),
  PaymentMethod(
    title: 'Transfer Bank',
    description: 'Transfer ke rekening penjual.',
  ),
];
