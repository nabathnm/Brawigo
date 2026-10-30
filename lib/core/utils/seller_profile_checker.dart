import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class SellerProfileStatus {
  final bool isComplete;
  final bool hasQris;
  final bool hasBank;
  final bool hasStoreName;
  final bool hasStoreAddress;
  final bool hasPhone;
  final List<String> missingFields;

  const SellerProfileStatus({
    required this.isComplete,
    required this.hasQris,
    required this.hasBank,
    required this.hasStoreName,
    required this.hasStoreAddress,
    required this.hasPhone,
    required this.missingFields,
  });

  static Future<SellerProfileStatus> check(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('qris_url, bank_name, bank_account_number, bank_account_holder, phone_number, bio')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        return const SellerProfileStatus(
          isComplete: false,
          hasQris: false,
          hasBank: false,
          hasStoreName: false,
          hasStoreAddress: false,
          hasPhone: false,
          missingFields: ['Nama Toko', 'Alamat Toko', 'Nomor Telepon', 'QRIS Toko', 'Rekening Bank'],
        );
      }

      Map<String, dynamic> bioMap = {};
      if (data['bio'] != null) {
        try {
          final decoded = jsonDecode(data['bio'].toString());
          if (decoded is Map<String, dynamic>) {
            bioMap = decoded;
          }
        } catch (_) {}
      }

      final qris = data['qris_url']?.toString().trim() ?? bioMap['qris_url']?.toString().trim();
      final bankName = data['bank_name']?.toString().trim();
      final bankAcc = data['bank_account_number']?.toString().trim();
      final storeName = bioMap['store_name']?.toString().trim();
      final storeAddress = bioMap['store_address']?.toString().trim();
      final phone = bioMap['store_phone']?.toString().trim() ?? data['phone_number']?.toString().trim();

      final hasQris = qris != null && qris.isNotEmpty;
      final hasBank = (bankName != null && bankName.isNotEmpty) && (bankAcc != null && bankAcc.isNotEmpty);
      final hasStoreName = storeName != null && storeName.isNotEmpty;
      final hasStoreAddress = storeAddress != null && storeAddress.isNotEmpty;
      final hasPhone = phone != null && phone.isNotEmpty;

      final missing = <String>[];
      if (!hasStoreName) missing.add('Nama Toko');
      if (!hasStoreAddress) missing.add('Alamat Toko');
      if (!hasPhone) missing.add('Nomor Telepon Toko');
      if (!hasQris) missing.add('QRIS Toko');
      if (!hasBank) missing.add('Rekening Bank');

      return SellerProfileStatus(
        isComplete: missing.isEmpty,
        hasQris: hasQris,
        hasBank: hasBank,
        hasStoreName: hasStoreName,
        hasStoreAddress: hasStoreAddress,
        hasPhone: hasPhone,
        missingFields: missing,
      );
    } catch (_) {
      return const SellerProfileStatus(
        isComplete: true,
        hasQris: true,
        hasBank: true,
        hasStoreName: true,
        hasStoreAddress: true,
        hasPhone: true,
        missingFields: [],
      );
    }
  }

  static void showIncompleteDialog(
    BuildContext context, {
    required VoidCallback onGoToProfile,
    VoidCallback? onEscapeToBuyer,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Lengkapi Pengaturan Toko',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15243C),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sebagai penjual, Anda harus melengkapi identitas toko dan data pembayaran terlebih dahulu agar pembeli dapat melakukan checkout:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 14),
            _buildCheckItem(Icons.storefront_rounded, 'Nama & Foto Profil Toko'),
            _buildCheckItem(Icons.location_on_outlined, 'Alamat Toko (untuk opsi ambil di toko)'),
            _buildCheckItem(Icons.phone_outlined, 'Nomor Kontak / WhatsApp Toko'),
            _buildCheckItem(Icons.qr_code_2_rounded, 'QRIS Toko (untuk metode bayar QRIS)'),
            _buildCheckItem(Icons.account_balance_rounded, 'Rekening Bank (untuk transfer)'),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B5F9E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  onGoToProfile();
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_note_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Lengkapi Profil Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  if (onEscapeToBuyer != null) {
                    onEscapeToBuyer();
                  } else {
                    context.go('/buyer');
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Kembali ke Halaman Buyer', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildCheckItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2B5F9E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15243C)),
            ),
          ),
        ],
      ),
    );
  }
}

