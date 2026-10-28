import '../../../../core/widgets/brawigo_toast.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'payment_confirmation_page.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const CheckoutPage({super.key, required this.product});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Pickup method: 'pickup', 'kurir'
  String? _selectedPickupMethod;
  String _pickupMethodTitle = '';
  String _pickupMethodSubtitle = '';

  // Pickup sub-fields
  final _meetupLocationController = TextEditingController();
  final _meetupTimeController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  String _sellerAddress = "Jl. Bunga Coklat, Jatimulyo, Kec. Lowokwaru, Kota Malang, Jawa Timur 65141";

  // Payment method: 'qris', 'transfer', 'cash'
  String? _selectedPaymentMethod;
  String _paymentMethodTitle = '';
  String _paymentMethodSubtitle = '';

  // Quantity
  int _quantity = 1;

  // Notes
  final _notesController = TextEditingController();

  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    // Default pickup time suggestion
    final futureDate = DateTime.now().add(const Duration(days: 1));
    try {
      _meetupTimeController.text = "${DateFormat('EEEE, d MMMM yyyy, HH:mm', 'id_ID').format(futureDate)} WIB";
    } catch (_) {
      _meetupTimeController.text = "${DateFormat('dd/MM/yyyy HH:mm').format(futureDate)} WIB";
    }
    _meetupLocationController.text = "Game Corner, Lantai 1 Gedung F FILKOM UB";
    _deliveryAddressController.text = "Jl. Sigura-gura, Sumbersari, Kec. Lowokwaru, Kota Malang, Jawa Timur 65141";
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final buyerProfile = await Supabase.instance.client
            .from('profiles')
            .select('bio')
            .eq('id', user.id)
            .maybeSingle();
        if (buyerProfile != null && buyerProfile['bio'] != null) {
          try {
            final bioData = jsonDecode(buyerProfile['bio'].toString());
            if (bioData is Map &&
                bioData['delivery_address'] != null &&
                bioData['delivery_address'].toString().trim().isNotEmpty) {
              if (mounted) {
                setState(() {
                  _deliveryAddressController.text =
                      bioData['delivery_address'].toString().trim();
                });
              }
            }
          } catch (_) {}
        }
      }

      final sellerId = widget.product['seller_id']?.toString();
      if (sellerId != null && sellerId.isNotEmpty) {
        final sellerProfile = await Supabase.instance.client
            .from('profiles')
            .select('bio')
            .eq('id', sellerId)
            .maybeSingle();
        if (sellerProfile != null && sellerProfile['bio'] != null) {
          try {
            final bioData = jsonDecode(sellerProfile['bio'].toString());
            if (bioData is Map &&
                bioData['store_address'] != null &&
                bioData['store_address'].toString().trim().isNotEmpty) {
              if (mounted) {
                setState(() {
                  _sellerAddress =
                      bioData['store_address'].toString().trim();
                });
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _meetupLocationController.dispose();
    _meetupTimeController.dispose();
    _deliveryAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _productPrice {
    final priceVal = widget.product['price'];
    if (priceVal == null) return 0.0;
    if (priceVal is num) return priceVal.toDouble();
    final cleanStr = priceVal.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanStr) ?? 0.0;
  }

  int get _maxStock {
    final stock = widget.product['stock'];
    if (stock == null) return 99;
    if (stock is int) return stock;
    return int.tryParse(stock.toString()) ?? 99;
  }

  double get _totalPrice => _productPrice * _quantity;

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2B5F9E),
              onPrimary: Colors.white,
              onSurface: Color(0xFF15243C),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2B5F9E),
              onPrimary: Colors.white,
              onSurface: Color(0xFF15243C),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      try {
        _meetupTimeController.text = "${DateFormat('EEEE, d MMMM yyyy, HH:mm', 'id_ID').format(combined)} WIB";
      } catch (_) {
        _meetupTimeController.text = "${DateFormat('dd/MM/yyyy HH:mm').format(combined)} WIB";
      }
    });
  }

  void _showPickupBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String tempSelected = _selectedPickupMethod ?? 'pickup';
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Pilih Cara Pengambilan",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15243C),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRadioOption(
                      title: "Self Pick-Up",
                      subtitle: "Temui penjual dan ambil langsung barangmu.",
                      value: "pickup",
                      groupValue: tempSelected,
                      onChanged: (val) => setModalState(() => tempSelected = val!),
                    ),
                    const SizedBox(height: 10),
                    _buildRadioOption(
                      title: "Kurir Instan",
                      subtitle: "Pesan sendiri layanan kurir instan pilihanmu.",
                      value: "kurir",
                      groupValue: tempSelected,
                      onChanged: (val) => setModalState(() => tempSelected = val!),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B5F9E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedPickupMethod = tempSelected;
                            if (tempSelected == 'pickup') {
                              _pickupMethodTitle = "Self Pick-Up";
                              _pickupMethodSubtitle = "Temui penjual dan ambil langsung barangmu.";
                            } else {
                              _pickupMethodTitle = "Kurir Instan";
                              _pickupMethodSubtitle = "Pesan sendiri layanan kurir instan pilihanmu.";
                            }
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Pilih Metode",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPaymentBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String tempSelected = _selectedPaymentMethod ?? 'qris';
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Pilih Metode Pembayaran",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15243C),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRadioOption(
                      title: "QRIS",
                      subtitle: "Bayar melalui QRIS Penjual.",
                      value: "qris",
                      groupValue: tempSelected,
                      onChanged: (val) => setModalState(() => tempSelected = val!),
                    ),
                    const SizedBox(height: 10),
                    _buildRadioOption(
                      title: "Transfer Bank",
                      subtitle: "Transfer ke rekening penjual.",
                      value: "transfer",
                      groupValue: tempSelected,
                      onChanged: (val) => setModalState(() => tempSelected = val!),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B5F9E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedPaymentMethod = tempSelected;
                            if (tempSelected == 'qris') {
                              _paymentMethodTitle = "QRIS";
                              _paymentMethodSubtitle = "Bayar melalui QRIS Penjual.";
                            } else if (tempSelected == 'transfer') {
                              _paymentMethodTitle = "Transfer Bank";
                              _paymentMethodSubtitle = "Transfer ke rekening penjual.";
                            } else {
                              _paymentMethodTitle = "Tunai / COD";
                              _paymentMethodSubtitle = "Bayar tunai saat bertemu penjual.";
                            }
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Pilih Metode",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final bool isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEBF3FC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2B5F9E) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15243C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: const Color(0xFF2B5F9E),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToPayment() {
    if (_selectedPickupMethod == null) {
      BrawigoToast.showWarning(
        context,
        message: 'Pilih metode pengambilan barang terlebih dahulu.',
        title: 'Pengambilan Barang Belum Dipilih',
      );
      return;
    }
    if (_selectedPaymentMethod == null) {
      BrawigoToast.showWarning(
        context,
        message: 'Pilih metode pembayaran yang ingin Anda gunakan.',
        title: 'Metode Pembayaran Belum Dipilih',
      );
      return;
    }

    if (_selectedPickupMethod == 'kurir' && _deliveryAddressController.text.trim().isEmpty) {
      BrawigoToast.showWarning(
        context,
        message: 'Masukkan alamat pengiriman Anda terlebih dahulu.',
        title: 'Alamat Pengiriman Wajib Diisi',
      );
      return;
    }

    final Map<String, dynamic> checkoutData = {
      'product': widget.product,
      'price': _totalPrice,

      'quantity': _quantity,
      'pickup_method': _selectedPickupMethod,
      'pickup_method_title': _pickupMethodTitle,
      'payment_method': _selectedPaymentMethod,
      'payment_method_title': _paymentMethodTitle,
      'meetup_location': _selectedPickupMethod == 'kurir'
          ? _deliveryAddressController.text.trim()
          : _sellerAddress,
      'meetup_time': _meetupTimeController.text.trim(),
      'delivery_address': _deliveryAddressController.text.trim(),
      'seller_address': _sellerAddress,
      'notes': _notesController.text.trim(),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentConfirmationPage(checkoutData: checkoutData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productName = widget.product['name'] ?? widget.product['product_name'] ?? 'Rice Cooker Mikoya';
    final imageUrl = widget.product['image_url'] ?? widget.product['thumbnail_url'] ?? '';
    final formattedPrice = _currencyFormat.format(_productPrice);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Color(0xFF15243C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Checkout",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15243C),
                        ),
                      ),
                      Text(
                        "Periksa kembali pesanan kamu",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION 1: Pesananmu ---
                    _buildSectionCard(
                      title: "Pesananmu",
                      icon: Icons.shopping_cart_outlined,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _placeholderImage(),
                                  )
                                : _placeholderImage(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15243C),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedPrice,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2B5F9E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (_quantity > 1) setState(() => _quantity--);
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: _quantity > 1
                                        ? const Color(0xFF2B5F9E)
                                        : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.remove, size: 16, color: Colors.white),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15243C),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (_quantity < _maxStock) setState(() => _quantity++);
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: _quantity < _maxStock
                                        ? const Color(0xFF2B5F9E)
                                        : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // --- SECTION 2: Pengambilan Barang ---
                    _buildSectionCard(
                      title: "Pengambilan Barang",
                      icon: Icons.inventory_2_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _showPickupBottomSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedPickupMethod != null ? const Color(0xFFEBF3FC) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedPickupMethod != null ? const Color(0xFF2B5F9E) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _selectedPickupMethod == null
                                        ? const Text(
                                            "Pilih Metode",
                                            style: TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                                          )
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _pickupMethodTitle,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF15243C),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _pickupMethodSubtitle,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
                                ],
                              ),
                            ),
                          ),

                          // Sub-fields berdasarkan metode
                          if (_selectedPickupMethod == 'pickup') ...[
                            const SizedBox(height: 12),
                            _buildInputLabel("Lokasi Penjual"),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                _sellerAddress,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF15243C), height: 1.4),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildInputLabel("Tanggal dan Waktu Pengambilan"),
                            InkWell(
                              onTap: _pickDateTime,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF2B5F9E)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _meetupTimeController.text.isNotEmpty
                                            ? _meetupTimeController.text
                                            : "Pilih Tanggal dan Waktu Pengambilan",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _meetupTimeController.text.isNotEmpty
                                              ? const Color(0xFF15243C)
                                              : const Color(0xFFA0AEC0),
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF64748B)),
                                  ],
                                ),
                              ),
                            ),
                          ] else if (_selectedPickupMethod == 'kurir') ...[
                            const SizedBox(height: 12),
                            _buildInputLabel("Alamat Pengiriman"),
                            _buildSubTextField(
                              controller: _deliveryAddressController,
                              hintText: "Jl. Sigura-gura, Sumbersari, Malang",
                              maxLines: 2,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // --- SECTION 3: Pembayaran ---
                    _buildSectionCard(
                      title: "Pembayaran",
                      icon: Icons.account_balance_wallet_outlined,
                      child: GestureDetector(
                        onTap: _showPaymentBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedPaymentMethod != null ? const Color(0xFFEBF3FC) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedPaymentMethod != null ? const Color(0xFF2B5F9E) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _selectedPaymentMethod == null
                                    ? const Text(
                                        "Pilih Metode",
                                        style: TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _paymentMethodTitle,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF15243C),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _paymentMethodSubtitle,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // --- SECTION 4: Catatan untuk Penjual ---
                    _buildSectionCard(
                      title: "Catatan untuk Penjual",
                      icon: Icons.edit_note_rounded,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _notesController,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF15243C)),
                          decoration: const InputDecoration(
                            hintText: "Tulis catatan...",
                            hintStyle: TextStyle(color: Color(0xFFA0AEC0), fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // --- SECTION 5: Ringkasan Pesanan ---
                    _buildSectionCard(
                      title: "Ringkasan Pesanan",
                      icon: Icons.receipt_long_outlined,
                      child: Column(
                        children: [
                          _buildSummaryRow("Harga Produk", formattedPrice),
                          const SizedBox(height: 6),
                          _buildSummaryRow("Jumlah", "${_quantity}x"),
                          const Divider(height: 20),
                          _buildSummaryRow("Subtotal", _currencyFormat.format(_totalPrice), isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // --- Bottom Bar ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Pesanan",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF15243C),
                        ),
                      ),
                      Text(
                        _currencyFormat.format(_totalPrice),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2B5F9E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B5F9E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _proceedToPayment,
                      child: const Text(
                        "Checkout",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF2B5F9E)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15243C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildSubTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13, color: Color(0xFF15243C)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? const Color(0xFF15243C) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: isBold ? const Color(0xFF2B5F9E) : const Color(0xFF15243C),
          ),
        ),
      ],
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 24),
    );
  }
}
