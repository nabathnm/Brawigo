class OrderDetail {
  const OrderDetail(this.data);

  final Map<String, dynamic> data;

  String get productName =>
      data['product_name_snapshot']?.toString() ?? 'Produk Brawigo';

  num get totalAmount =>
      (data['total_amount'] as num?) ??
      (data['product_price_snapshot'] as num?) ??
      0;

  String get paymentMethod => data['payment_method']?.toString() ?? 'COD';
  String get status =>
      (data['order_status'] ?? data['status'] ?? 'created')
          .toString()
          .toLowerCase();
  String? get proofUrl => data['payment_proof_url']?.toString();
  String get meetupLocation => data['meetup_location']?.toString() ?? '-';
  String get meetupTime => data['meetup_time']?.toString() ?? '-';
  String get quantity => data['quantity']?.toString() ?? '1';
  String? get notes => data['notes']?.toString();
  String? get thumbnailUrl => data['thumbnail_url_snapshot']?.toString();
  String? get sellerId => data['seller_id']?.toString();
  String? get createdAt => data['created_at']?.toString();
}
