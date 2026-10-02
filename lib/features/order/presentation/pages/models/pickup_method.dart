class PickupMethod {
  final String title;
  final String description;

  const PickupMethod({required this.title, required this.description});
}

const pickupMethods = [
  PickupMethod(
    title: 'Cash on Delivery (COD)',
    description: 'Bertemu dengan penjual di sekitar area UB.',
  ),
  PickupMethod(
    title: 'Self Pick-Up',
    description: 'Ambil barang langsung dari penjual.',
  ),
  PickupMethod(
    title: 'Kurir Instan',
    description: 'Barang dikirim menggunakan kurir instan.',
  ),
];
