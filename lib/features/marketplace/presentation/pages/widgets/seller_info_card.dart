import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';

class SellerInfoCard extends StatelessWidget {
  const SellerInfoCard({
    super.key,
    required this.profileFuture,
    required this.onTap,
  });

  final Future<Map<String, dynamic>?> profileFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrawigoColors.blue50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _sellerProfile()),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A7EBB),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text(
                  'Kunjungi Toko',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _SellerMetric(value: '12', label: 'Produk'),
              _SellerMetric(value: '4.9', label: 'Penilaian'),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF475569)),
                  SizedBox(width: 4),
                  Text(
                    'Tlogomas, Malang',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2B5F9E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _sellerProfile() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: profileFuture,
      builder: (context, snapshot) {
        var sellerName = 'Memuat...';
        String? photoUrl;

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data != null) {
            final profile = snapshot.data!;
            String? storeName;
            String? storePhotoUrl;
            final bio = profile['bio'];
            if (bio != null) {
              try {
                final decoded = jsonDecode(bio.toString());
                if (decoded is Map) {
                  storeName = decoded['store_name']?.toString().trim();
                  storePhotoUrl = decoded['store_photo_url']?.toString().trim();
                }
              } catch (_) {
                // Bio tidak selalu berisi JSON; gunakan data profil biasa.
              }
            }

            final username = profile['username']?.toString().trim();
            final fullName = profile['full_name']?.toString().trim();
            photoUrl = (storePhotoUrl != null && storePhotoUrl.isNotEmpty)
                ? storePhotoUrl
                : profile['profile_photo_url']?.toString().trim();

            if (storeName != null && storeName.isNotEmpty) {
              sellerName = storeName;
            } else if (username != null && username.isNotEmpty && username != '-') {
              sellerName = username;
            } else if (fullName != null && fullName.isNotEmpty) {
              sellerName = fullName;
            } else {
              sellerName = 'Penjual';
            }
          } else {
            sellerName = 'Penjual Tidak Diketahui';
          }
        }

        return Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF4A7EBB),
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl == null || photoUrl.isEmpty
                  ? Text(
                      sellerName.isNotEmpty ? sellerName[0].toUpperCase() : 'P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sellerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15243C),
                    ),
                  ),
                  const Text(
                    'Aktif baru saja',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SellerMetric extends StatelessWidget {
  const _SellerMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
        children: [
          TextSpan(
            text: '$value ',
            style: const TextStyle(
              color: Color(0xFF2B5F9E),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: label),
        ],
      ),
    );
  }
}
