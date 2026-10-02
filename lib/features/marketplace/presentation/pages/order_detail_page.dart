import 'package:flutter/material.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  final String paymentMethod; // 'QRIS', 'Transfer', or 'COD'
  final String productTitle;
  final String price;
  final String buyerName;

  const OrderDetailPage({
    super.key,
    this.orderId = 'ID20346-218',
    this.paymentMethod = 'QRIS',
    this.productTitle = 'Magic Com Biru',
    this.price = 'Rp 200.000',
    this.buyerName = 'Hassan Nasrullah',
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  // For COD interactive flow:
  // 0: Initial Review (Screen 2) / QRIS Review (Screen 1)
  // 1: Prompt Yakin Menerima (Screen 3)
  // 2: Pesanan Dikonfirmasi / Siapkan Barang (Screen 4)
  // 3: Dalam Proses Meetup (Screen 5)
  late int _stepState;
  bool _isPaymentDetailsExpanded = true;

  bool get isCOD => widget.paymentMethod.toUpperCase() == 'COD';

  @override
  void initState() {
    super.initState();
    _stepState = 0;
  }

  String get _appBarTitle {
    if (_stepState == 0) return 'Detail Pesanan';
    return 'Konfirmasi Pesanan';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Color(0xFF1E293B),
          ),
          onPressed: () {
            if (_stepState > 0 && isCOD) {
              setState(() {
                _stepState--;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          children: [
            Text(
              _appBarTitle,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.orderId,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TOP STATE-SPECIFIC NOTICE BANNERS ---
                    if (isCOD && _stepState == 0) _buildCodUrgentBanner(),
                    if (isCOD && _stepState == 1) _buildConfirmPromptCard(),
                    if (isCOD && _stepState == 2) _buildSiapkanBarangBanner(),
                    if (isCOD && _stepState == 3) _buildDalamPerjalananBanner(),

                    // --- STEPPER FOR COD STATE 2 & 3 ---
                    if (isCOD && (_stepState == 2 || _stepState == 3)) ...[
                      const SizedBox(height: 16),
                      _buildCodStatusStepper(),
                    ],

                    const SizedBox(height: 16),

                    // --- ORDER INFORMATION ---
                    _buildInformasiPesananCard(),
                    const SizedBox(height: 16),

                    // --- BUYER INFORMATION ---
                    _buildInformasiPembeliCard(),
                    const SizedBox(height: 16),

                    // --- PRODUCT ITEM INFORMATION ---
                    _buildPesananItemCard(),
                    const SizedBox(height: 16),

                    // --- COD SCHEDULE & LOCATION (If COD) ---
                    if (isCOD) ...[
                      _buildJadwalDanLokasiCard(),
                      const SizedBox(height: 16),
                    ],

                    // --- CHECKLIST SEBELUM KONFIRMASI (Screen 3) ---
                    if (isCOD && _stepState == 1) ...[
                      _buildChecklistCard(),
                      const SizedBox(height: 16),
                    ],

                    // --- PAYMENT DETAILS (Screen 1 & 2) ---
                    if (_stepState == 0) ...[
                      _buildDetailPembayaranCard(),
                      const SizedBox(height: 16),
                    ],

                    // --- COD CASH NOTICE (Screen 2) ---
                    if (isCOD && _stepState == 0) ...[
                      _buildCodCashNotice(),
                      const SizedBox(height: 16),
                    ],

                    // --- BUKTI PEMBAYARAN (QRIS/Transfer only, Screen 1) ---
                    if (!isCOD && _stepState == 0) ...[
                      _buildBuktiPembayaranCard(),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
            // --- BOTTOM ACTION BUTTONS ---
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  // --- TOP NOTICE CARDS ---

  Widget _buildCodUrgentBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9DB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.notification_important_outlined,
            color: Color(0xFFD97706),
            size: 22,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yuk Segera Respons',
                  style: TextStyle(
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Konfirmasi sebelum batas waktu agar buyer tidak menunggu lama',
                  style: TextStyle(color: Color(0xFFB45309), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPromptCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1890FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1890FF).withAlpha(20),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.thumb_up_alt_outlined,
              color: Color(0xFF16A34A),
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Yakin menerima pesanan ini?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Setelah konfirmasi, status berubah ke Pesanan Dikonfirmasi dan buyer mendapat notifikasi. Pastikan barang siap sediakan dan temu di lokasi meetup tepat waktu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiapkanBarangBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Siapkan Barang Sekarang!',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Buyer sudah mendapat notifikasi. Siapkan barang dan menuju lokasi meetup tepat waktu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Pesanan Dikonfirmasi',
              style: TextStyle(
                color: Color(0xFF0369A1),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDalamPerjalananBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send_rounded,
              color: Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Kamu sedang dalam perjalanan!',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Segera menuju lokasi meetup. Buyer sedang menuju di lokasi meetup.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Dalam proses meetup',
              style: TextStyle(
                color: Color(0xFF1D4ED8),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEPPER WIDGET ---

  Widget _buildCodStatusStepper() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status COD',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildStepItem(
            title: 'Pesanan Dibuat',
            isDone: true,
            isCurrent: false,
            isLast: false,
          ),
          _buildStepItem(
            title: 'Pesanan Dikonfirmasi',
            isDone: _stepState > 2,
            isCurrent: _stepState == 2,
            subtitle: _stepState == 2 ? 'Saat Ini' : null,
            isLast: false,
          ),
          _buildStepItem(
            title: 'Dalam Proses Meetup',
            isDone: _stepState > 3,
            isCurrent: _stepState == 3,
            subtitle: _stepState == 3 ? 'Saat Ini' : null,
            isLast: false,
          ),
          _buildStepItem(
            title: 'Selesai',
            isDone: false,
            isCurrent: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String title,
    required bool isDone,
    required bool isCurrent,
    String? subtitle,
    required bool isLast,
  }) {
    Color dotColor = Colors.grey.shade300;
    Widget dotChild = const SizedBox();
    if (isDone) {
      dotColor = const Color(0xFF16A34A);
      dotChild = const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (isCurrent) {
      dotColor = const Color(0xFF2563EB);
      dotChild = Container(
        margin: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
              child: Center(child: dotChild),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isDone ? const Color(0xFF16A34A) : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: (isDone || isCurrent)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: (isDone || isCurrent)
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF94A3B8),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- CONTENT SECTION CARDS ---

  Widget _buildInformasiPesananCard() {
    String badgeText = 'Bukti Pembayaran Menunggu Konfirmasi';
    Color badgeBg = const Color(0xFFDCEBFA);
    Color badgeTextCol = const Color(0xFF1D4E89);

    if (isCOD) {
      badgeText = 'Menunggu Konfirmasi Penjual';
      badgeBg = const Color(0xFFFEF3C7);
      badgeTextCol = const Color(0xFFB45309);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF4A5D70),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Informasi Pesanan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Text(
                '9 Juli 2026, 10:24',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order ID',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.orderId,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeTextCol,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInformasiPembeliCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF4A5D70),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Informasi Pembeli',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundImage: AssetImage('assets/images/avatar.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.buyerName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            '(+62 821-8705-4225)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Mahasiswa UB',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4A5D70),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Terverifikasi',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPesananItemCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFF4A5D70),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Pesanan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Text(
                'Total 1 item',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EFF8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1544816155-12df9643f363?q=80&w=300&auto=format&fit=crop',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.kitchen_rounded,
                      color: Color(0xFF4A6884),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.productTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Biru',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.price,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B3B60),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '1x',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A5D70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Text(
            isCOD
                ? 'Catatan: Tolong barangnya dibungkus yang rapi ya kak'
                : 'Catatan: -',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4A5D70),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalDanLokasiCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.handshake_outlined,
                color: Color(0xFF4A5D70),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Jadwal & Lokasi COD',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Color(0xFF2E6399),
                size: 22,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lokasi COD',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Game Corner Gedung F Filkom UB',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.access_time_rounded,
                color: Color(0xFF2E6399),
                size: 22,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waktu COD',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kamis, 9 Juli 2026 | Pukul 10.00 WIB',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Checklist Sebelum Konfirmasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 12),
          _ChecklistItem(text: 'Barang dalam kondisi siap dan sesuai deskripsi'),
          SizedBox(height: 8),
          _ChecklistItem(text: 'Tersedia pada Hari ini 13.00-14.00'),
          SizedBox(height: 8),
          _ChecklistItem(text: 'Siap menerima tunai Rp 185.000 / Rp 190.000'),
          SizedBox(height: 8),
          _ChecklistItem(
            text: 'Bisa hadir di Game Corner Gedung F Filkom UB',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPembayaranCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.monetization_on_outlined,
                color: Color(0xFF4A5D70),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Detail Pembayaran',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          if (_isPaymentDetailsExpanded) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pesanan',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
                Text(
                  widget.price,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Promo',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
                Text(
                  '-Rp 10.000',
                  style: TextStyle(
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            if (!isCOD) ...[
              const Text(
                'Transaksi ID 234527172180',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isCOD
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFDCEBFA),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.paymentMethod,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isCOD
                              ? const Color(0xFFD97706)
                              : const Color(0xFF1D4E89),
                        ),
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Rp 190.000',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B3B60),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Center(
            child: InkWell(
              onTap: () {
                setState(() {
                  _isPaymentDetailsExpanded = !_isPaymentDetailsExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isPaymentDetailsExpanded
                          ? 'Sembunyikan'
                          : 'Lihat Selengkapnya',
                      style: const TextStyle(
                        color: Color(0xFF2E6399),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isPaymentDetailsExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF2E6399),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodCashNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.payments_outlined, color: Color(0xFF2563EB), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Buyer akan membayar tunai saat bertemu di lokasi meetup',
              style: TextStyle(
                color: Color(0xFF1E40AF),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuktiPembayaranCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.image_outlined,
                color: Color(0xFF4A5D70),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Bukti Pembayaran',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2EAF4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF2E6399),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'bukti.jpg',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '2.4 MB • File berhasil diupload',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nominal diklaim',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              Text(
                'Rp 190.000',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- BOTTOM ACTION BAR ---

  Widget _buildBottomActionBar() {
    String primaryBtnText = 'Terima Pembayaran';
    String secondaryBtnText = 'Tolak Pembayaran';
    VoidCallback onPrimaryPressed = () {};
    VoidCallback onSecondaryPressed = () => Navigator.pop(context);

    if (isCOD) {
      if (_stepState == 0) {
        primaryBtnText = 'Terima Pembayaran';
        onPrimaryPressed = () => setState(() => _stepState = 1);
      } else if (_stepState == 1) {
        primaryBtnText = 'Ya, Konfirmasi Pesanan';
        secondaryBtnText = 'Kembali';
        onPrimaryPressed = () => setState(() => _stepState = 2);
      } else if (_stepState == 2) {
        primaryBtnText = 'Saya Sudah di Lokasi';
        secondaryBtnText = 'Kembali';
        onPrimaryPressed = () => setState(() => _stepState = 3);
      } else if (_stepState == 3) {
        primaryBtnText = 'Saya Sudah di Lokasi';
        secondaryBtnText = 'Kembali';
        onPrimaryPressed = () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesanan berhasil diselesaikan!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        };
      }
    } else {
      onPrimaryPressed = () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran diverifikasi! Pesanan diterima.'),
            backgroundColor: Colors.blue,
          ),
        );
        Navigator.pop(context);
      };
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4580C2), Color(0xFF163C66)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF163C66).withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onPrimaryPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  primaryBtnText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: onSecondaryPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2E6399), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                secondaryBtnText,
                style: const TextStyle(
                  color: Color(0xFF2E6399),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1E2D3D).withAlpha(12),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String text;
  const _ChecklistItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF4A5D70)),
          ),
        ),
      ],
    );
  }
}
