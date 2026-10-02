enum PickupMethod { cod, selfPickup, instantCourier }

class PickupMethodItem {
  final PickupMethod type;
  final String title;
  final String description;

  const PickupMethodItem({
    required this.type,
    required this.title,
    required this.description,
  });
}

const List<PickupMethodItem> pickupMethods = [
  PickupMethodItem(
    type: PickupMethod.cod,
    title: 'Cash on Delivery (COD)',
    description: 'Bertemu dengan penjual di sekitar area UB.',
  ),
  PickupMethodItem(
    type: PickupMethod.selfPickup,
    title: 'Self Pick-Up',
    description: 'Ambil barang langsung dari penjual.',
  ),
  PickupMethodItem(
    type: PickupMethod.instantCourier,
    title: 'Kurir Instan',
    description: 'Barang dikirim menggunakan kurir instan.',
  ),
];
