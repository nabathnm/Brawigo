// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'payment_confirmation_page.dart';

// class CheckoutPage extends StatefulWidget {
//   final Map<String, dynamic> product;

//   const CheckoutPage({super.key, required this.product});

//   @override
//   State<CheckoutPage> createState() => _CheckoutPageState();
// }

// class _CheckoutPageState extends State<CheckoutPage> {
//   // Pickup method: 'cod', 'pickup', 'kurir'
//   String? _selectedPickupMethod;
//   String _pickupMethodTitle = '';
//   String _pickupMethodSubtitle = '';

//   // Pickup sub-fields
//   final _meetupLocationController = TextEditingController();
//   final _meetupTimeController = TextEditingController();
//   final _deliveryAddressController = TextEditingController();
//   final _sellerAddress = "Jl. Bunga Coklat, Jatimulyo, Kec. Lowokwaru, Kota Malang, Jawa Timur 65141";

//   // Payment method: 'qris', 'transfer', 'cash'
//   String? _selectedPaymentMethod;
//   String _paymentMethodTitle = '';
//   String _paymentMethodSubtitle = '';

//   // Notes
//   final _notesController = TextEditingController();

//   final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

//   @override
//   void initState() {
//     super.initState();
//     // Default pickup time suggestion
//     final futureDate = DateTime.now().add(const Duration(days: 1));
//     try {
//       _meetupTimeController.text = "${DateFormat('EEEE, d MMMM yyyy, HH:mm', 'id_ID').format(futureDate)} WIB";
//     } catch (_) {
//       _meetupTimeController.text = "${DateFormat('dd/MM/yyyy HH:mm').format(futureDate)} WIB";
//     }
//     _meetupLocationController.text = "Game Corner, Lantai 1 Gedung F FILKOM UB";
//     _deliveryAddressController.text = "Jl. Sigura-gura, Sumbersari, Kec. Lowokwaru, Kota Malang, Jawa Timur 65141";
//   }

//   @override
//   void dispose() {
//     _meetupLocationController.dispose();
//     _meetupTimeController.dispose();
//     _deliveryAddressController.dispose();
//     _notesController.dispose();
//     super.dispose();
//   }

//   double get _productPrice {
//     final priceVal = widget.product['price'];
//     if (priceVal == null) return 0.0;
//     if (priceVal is num) return priceVal.toDouble();
//     final cleanStr = priceVal.toString().replaceAll(RegExp(r'[^0-9.]'), '');
//     return double.tryParse(cleanStr) ?? 0.0;
//   }

//   void _showPickupBottomSheet() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         String tempSelected = _selectedPickupMethod ?? 'cod';
//         return StatefulBuilder(
//           builder: (context, setModalState) {
//             return SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 40,
//                         height: 4,
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade300,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     const Text(
//                       "Pilih Cara Pengambilan",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF15243C),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     _buildRadioOption(
//                       title: "Cash on Delivery (COD)",
//                       subtitle: "Bertemu dengan penjual di sekitar area UB.",
//                       value: "cod",
//                       groupValue: tempSelected,
//                       onChanged: (val) => setModalState(() => tempSelected = val!),
//                     ),
//                     const SizedBox(height: 10),
//                     _buildRadioOption(
//                       title: "Self Pick-Up",
//                       subtitle: "Ambil langsung di lokasi penjual.",
//                       value: "pickup",
//                       groupValue: tempSelected,
//                       onChanged: (val) => setModalState(() => tempSelected = val!),
//                     ),
//                     const SizedBox(height: 10),
//                     _buildRadioOption(
//                       title: "Kurir Instan",
//                       subtitle: "Pesan sendiri layanan kurir instan pilihanmu.",
//                       value: "kurir",
//                       groupValue: tempSelected,
//                       onChanged: (val) => setModalState(() => tempSelected = val!),
//                     ),
//                     const SizedBox(height: 24),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 48,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF2B5F9E),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _selectedPickupMethod = tempSelected;
//                             if (tempSelected == 'cod') {
//                               _pickupMethodTitle = "Cash on Delivery (COD)";
//                               _pickupMethodSubtitle = "Bertemu dengan penjual di sekitar area UB.";
//                             } else if (tempSelected == 'pickup') {
//                               _pickupMethodTitle = "Self Pick-Up";
//                               _pickupMethodSubtitle = "Ambil langsung di lokasi penjual.";
//                             } else {
//                               _pickupMethodTitle = "Kurir Instan";
//                               _pickupMethodSubtitle = "Pesan sendiri layanan kurir instan pilihanmu.";
//                             }
//                           });
//                           Navigator.pop(context);
//                         },
//                         child: const Text(
//                           "Pilih Metode",
//                           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   void _showPaymentBottomSheet() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         String tempSelected = _selectedPaymentMethod ?? 'qris';
//         return StatefulBuilder(
//           builder: (context, setModalState) {
//             return SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 40,
//                         height: 4,
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade300,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     const Text(
//                       "Pilih Metode Pembayaran",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF15243C),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     _buildRadioOption(
//                       title: "QRIS",
//                       subtitle: "Bayar melalui QRIS Penjual.",
//                       value: "qris",
//                       groupValue: tempSelected,
//                       onChanged: (val) => setModalState(() => tempSelected = val!),
//                     ),
//                     const SizedBox(height: 10),
//                     _buildRadioOption(
//                       title: "Transfer Bank",
//                       subtitle: "Transfer ke rekening penjual.",
//                       value: "transfer",
//                       groupValue: tempSelected,
//                       onChanged: (val) => setModalState(() => tempSelected = val!),
//                     ),
//                     if (_selectedPickupMethod == 'cod') ...[
//                       const SizedBox(height: 10),
//                       _buildRadioOption(
//                         title: "Tunai / COD",
//                         subtitle: "Bayar tunai saat bertemu penjual.",
//                         value: "cash",
//                         groupValue: tempSelected,
//                         onChanged: (val) => setModalState(() => tempSelected = val!),
//                       ),
//                     ],
//                     const SizedBox(height: 24),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 48,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF2B5F9E),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _selectedPaymentMethod = tempSelected;
//                             if (tempSelected == 'qris') {
//                               _paymentMethodTitle = "QRIS";
//                               _paymentMethodSubtitle = "Bayar melalui QRIS Penjual.";
//                             } else if (tempSelected == 'transfer') {
//                               _paymentMethodTitle = "Transfer Bank";
//                               _paymentMethodSubtitle = "Transfer ke rekening penjual.";
//                             } else {
//                               _paymentMethodTitle = "Tunai / COD";
//                               _paymentMethodSubtitle = "Bayar tunai saat bertemu penjual.";
//                             }
//                           });
//                           Navigator.pop(context);
//                         },
//                         child: const Text(
//                           "Pilih Metode",
//                           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildRadioOption({
//     required String title,
//     required String subtitle,
//     required String value,
//     required String groupValue,
//     required ValueChanged<String?> onChanged,
//   }) {
//     final bool isSelected = value == groupValue;
//     return GestureDetector(
//       onTap: () => onChanged(value),
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: isSelected ? const Color(0xFFEBF3FC) : Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: isSelected ? const Color(0xFF2B5F9E) : const Color(0xFFE2E8F0),
//             width: 1.5,
//           ),
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF15243C),
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     subtitle,
//                     style: const TextStyle(
//                       fontSize: 12,
//                       color: Color(0xFF64748B),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Radio<String>(
//               value: value,
//               groupValue: groupValue,
//               onChanged: onChanged,
//               activeColor: const Color(0xFF2B5F9E),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _proceedToPayment() {
//     if (_selectedPickupMethod == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Pilih metode pengambilan barang terlebih dahulu.')),
//       );
//       return;
//     }
//     if (_selectedPaymentMethod == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Pilih metode pembayaran terlebih dahulu.')),
//       );
//       return;
//     }

//     final Map<String, dynamic> checkoutData = {
//       'product': widget.product,
//       'price': _productPrice,
//       'pickup_method': _selectedPickupMethod,
//       'pickup_method_title': _pickupMethodTitle,
//       'payment_method': _selectedPaymentMethod,
//       'payment_method_title': _paymentMethodTitle,
//       'meetup_location': _meetupLocationController.text.trim(),
//       'meetup_time': _meetupTimeController.text.trim(),
//       'delivery_address': _deliveryAddressController.text.trim(),
//       'seller_address': _sellerAddress,
//       'notes': _notesController.text.trim(),
//     };

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => PaymentConfirmationPage(checkoutData: checkoutData),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final productName = widget.product['name'] ?? widget.product['product_name'] ?? 'Rice Cooker Mikoya';
//     final imageUrl = widget.product['image_url'] ?? widget.product['thumbnail_url'] ?? '';
//     final formattedPrice = _currencyFormat.format(_productPrice);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF1F5F9),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // --- Header ---
//             Container(
//               color: Colors.white,
//               padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
//               child: Row(
//                 children: [
//                   GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: Container(
//                       width: 36,
//                       height: 36,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFF1F5F9),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: const Icon(
//                         Icons.arrow_back_ios_new_rounded,
//                         size: 18,
//                         color: Color(0xFF15243C),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 14),
//                   const Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Checkout",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF15243C),
//                         ),
//                       ),
//                       Text(
//                         "Periksa kembali pesanan kamu",
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Color(0xFF64748B),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // --- SECTION 1: Pesananmu ---
//                     _buildSectionCard(
//                       title: "Pesananmu",
//                       icon: Icons.shopping_cart_outlined,
//                       child: Row(
//                         children: [
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(8),
//                             child: imageUrl.isNotEmpty
//                                 ? Image.network(
//                                     imageUrl,
//                                     width: 60,
//                                     height: 60,
//                                     fit: BoxFit.cover,
//                                     errorBuilder: (_, __, ___) => _placeholderImage(),
//                                   )
//                                 : _placeholderImage(),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   productName,
//                                   style: const TextStyle(
//                                     fontSize: 15,
//                                     fontWeight: FontWeight.bold,
//                                     color: Color(0xFF15243C),
//                                   ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   formattedPrice,
//                                   style: const TextStyle(
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w700,
//                                     color: Color(0xFF2B5F9E),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const Text(
//                             "1x",
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF64748B),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 14),

//                     // --- SECTION 2: Pengambilan Barang ---
//                     _buildSectionCard(
//                       title: "Pengambilan Barang",
//                       icon: Icons.inventory_2_outlined,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           GestureDetector(
//                             onTap: _showPickupBottomSheet,
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//                               decoration: BoxDecoration(
//                                 color: _selectedPickupMethod != null ? const Color(0xFFEBF3FC) : const Color(0xFFF8FAFC),
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(
//                                   color: _selectedPickupMethod != null ? const Color(0xFF2B5F9E) : const Color(0xFFCBD5E1),
//                                 ),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Expanded(
//                                     child: _selectedPickupMethod == null
//                                         ? const Text(
//                                             "Pilih Metode",
//                                             style: TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
//                                           )
//                                         : Column(
//                                             crossAxisAlignment: CrossAxisAlignment.start,
//                                             children: [
//                                               Text(
//                                                 _pickupMethodTitle,
//                                                 style: const TextStyle(
//                                                   fontSize: 14,
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Color(0xFF15243C),
//                                                 ),
//                                               ),
//                                               const SizedBox(height: 2),
//                                               Text(
//                                                 _pickupMethodSubtitle,
//                                                 style: const TextStyle(
//                                                   fontSize: 12,
//                                                   color: Color(0xFF64748B),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                   ),
//                                   const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
//                                 ],
//                               ),
//                             ),
//                           ),

//                           // Sub-fields berdasarkan metode
//                           if (_selectedPickupMethod == 'cod') ...[
//                             const SizedBox(height: 12),
//                             _buildInputLabel("Lokasi Meetup"),
//                             _buildSubTextField(
//                               controller: _meetupLocationController,
//                               hintText: "Game Corner, Lantai 1 Gedung F FILKOM UB",
//                             ),
//                             const SizedBox(height: 10),
//                             _buildInputLabel("Tanggal dan Waktu Meetup"),
//                             _buildSubTextField(
//                               controller: _meetupTimeController,
//                               hintText: "Kamis, 9 Juli 2026, 10.00 WIB",
//                             ),
//                           ] else if (_selectedPickupMethod == 'pickup') ...[
//                             const SizedBox(height: 12),
//                             _buildInputLabel("Lokasi Penjual"),
//                             Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFF8FAFC),
//                                 borderRadius: BorderRadius.circular(10),
//                                 border: Border.all(color: const Color(0xFFE2E8F0)),
//                               ),
//                               child: Text(
//                                 _sellerAddress,
//                                 style: const TextStyle(fontSize: 13, color: Color(0xFF15243C), height: 1.4),
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             _buildInputLabel("Tanggal dan Waktu Pengambilan"),
//                             _buildSubTextField(
//                               controller: _meetupTimeController,
//                               hintText: "Kamis, 9 Juli 2026, 10.00 WIB",
//                             ),
//                           ] else if (_selectedPickupMethod == 'kurir') ...[
//                             const SizedBox(height: 12),
//                             _buildInputLabel("Alamat Pengiriman"),
//                             _buildSubTextField(
//                               controller: _deliveryAddressController,
//                               hintText: "Jl. Sigura-gura, Sumbersari, Malang",
//                               maxLines: 2,
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 14),

//                     // --- SECTION 3: Pembayaran ---
//                     _buildSectionCard(
//                       title: "Pembayaran",
//                       icon: Icons.account_balance_wallet_outlined,
//                       child: GestureDetector(
//                         onTap: _showPaymentBottomSheet,
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//                           decoration: BoxDecoration(
//                             color: _selectedPaymentMethod != null ? const Color(0xFFEBF3FC) : const Color(0xFFF8FAFC),
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(
//                               color: _selectedPaymentMethod != null ? const Color(0xFF2B5F9E) : const Color(0xFFCBD5E1),
//                             ),
//                           ),
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 child: _selectedPaymentMethod == null
//                                     ? const Text(
//                                         "Pilih Metode",
//                                         style: TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
//                                       )
//                                     : Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             _paymentMethodTitle,
//                                             style: const TextStyle(
//                                               fontSize: 14,
//                                               fontWeight: FontWeight.bold,
//                                               color: Color(0xFF15243C),
//                                             ),
//                                           ),
//                                           const SizedBox(height: 2),
//                                           Text(
//                                             _paymentMethodSubtitle,
//                                             style: const TextStyle(
//                                               fontSize: 12,
//                                               color: Color(0xFF64748B),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                               ),
//                               const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 14),

//                     // --- SECTION 4: Catatan untuk Penjual ---
//                     _buildSectionCard(
//                       title: "Catatan untuk Penjual",
//                       icon: Icons.edit_note_rounded,
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFF8FAFC),
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(color: const Color(0xFFE2E8F0)),
//                         ),
//                         child: TextField(
//                           controller: _notesController,
//                           maxLines: 2,
//                           style: const TextStyle(fontSize: 13, color: Color(0xFF15243C)),
//                           decoration: const InputDecoration(
//                             hintText: "Tulis catatan...",
//                             hintStyle: TextStyle(color: Color(0xFFA0AEC0), fontSize: 13),
//                             border: InputBorder.none,
//                             contentPadding: EdgeInsets.all(12),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 14),

//                     // --- SECTION 5: Ringkasan Pesanan ---
//                     _buildSectionCard(
//                       title: "Ringkasan Pesanan",
//                       icon: Icons.receipt_long_outlined,
//                       child: Column(
//                         children: [
//                           _buildSummaryRow("Harga Produk", formattedPrice),
//                           const SizedBox(height: 6),
//                           _buildSummaryRow("Jumlah", "1x"),
//                           const Divider(height: 20),
//                           _buildSummaryRow("Subtotal", formattedPrice, isBold: true),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),

//             // --- Bottom Bar ---
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.06),
//                     blurRadius: 10,
//                     offset: const Offset(0, -4),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         "Total Pesanan",
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF15243C),
//                         ),
//                       ),
//                       Text(
//                         formattedPrice,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w900,
//                           color: Color(0xFF2B5F9E),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 48,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF2B5F9E),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 0,
//                       ),
//                       onPressed: _proceedToPayment,
//                       child: const Text(
//                         "Checkout",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionCard({
//     required String title,
//     required IconData icon,
//     required Widget child,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.04),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, size: 20, color: const Color(0xFF2B5F9E)),
//               const SizedBox(width: 8),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF15243C),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           child,
//         ],
//       ),
//     );
//   }

//   Widget _buildInputLabel(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 4),
//       child: Text(
//         text,
//         style: const TextStyle(
//           fontSize: 12,
//           fontWeight: FontWeight.w600,
//           color: Color(0xFF64748B),
//         ),
//       ),
//     );
//   }

//   Widget _buildSubTextField({
//     required TextEditingController controller,
//     required String hintText,
//     int maxLines = 1,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFFF8FAFC),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: const Color(0xFFE2E8F0)),
//       ),
//       child: TextField(
//         controller: controller,
//         maxLines: maxLines,
//         style: const TextStyle(fontSize: 13, color: Color(0xFF15243C)),
//         decoration: InputDecoration(
//           hintText: hintText,
//           hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 13),
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         ),
//       ),
//     );
//   }

//   Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 13,
//             fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
//             color: isBold ? const Color(0xFF15243C) : const Color(0xFF64748B),
//           ),
//         ),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
//             color: isBold ? const Color(0xFF2B5F9E) : const Color(0xFF15243C),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _placeholderImage() {
//     return Container(
//       width: 60,
//       height: 60,
//       color: Colors.grey.shade200,
//       child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 24),
//     );
//   }
// }
