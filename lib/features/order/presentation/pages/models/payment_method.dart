class PaymentMethod {
  final String title;
  final String description;

  const PaymentMethod({required this.title, required this.description});
}

const paymentMethods = [
  PaymentMethod(
    title: 'Cash on Delivery (COD)',
    description: 'Bertemu dengan penjual di sekitar area UB.',
  ),
  PaymentMethod(
    title: 'Self Pick-Up',
    description: 'Ambil barang langsung dari penjual.',
  ),
  PaymentMethod(
    title: 'Kurir Instan',
    description: 'Barang dikirim menggunakan kurir instan.',
  ),
];
