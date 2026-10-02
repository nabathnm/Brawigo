import 'package:flutter/material.dart';

import 'package:brawigo/core/utils/constants/brawigo_colors.dart';

import '../models/pickup_method.dart';

class PickupMethodSelector extends StatelessWidget {
  final PickupMethod? selectedMethod;
  final VoidCallback onTap;
  final TextEditingController locationController;
  final TextEditingController timeController;

  const PickupMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onTap,
    required this.locationController,
    required this.timeController,
  });

  @override
  Widget build(BuildContext context) {
    final selectedItem = selectedMethod == null
        ? null
        : pickupMethods.firstWhere((method) => method.type == selectedMethod);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xffffffff),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/icons/marketplace/package.png'),
                const SizedBox(width: 8),
                Text(
                  'Pengambilan Barang',
                  style: TextStyle(
                    color: BrawigoColors.blue800,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: selectedItem != null
                    ? BrawigoColors.blue100
                    : Colors.white,
                border: Border.all(
                  color: selectedItem != null
                      ? const Color(0xff20395A).withValues(alpha: 0.3)
                      : Colors.grey.shade400,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: selectedItem == null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pilih Metode',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(
                              0xff20395A,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedItem.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: BrawigoColors.blue800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedItem.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: BrawigoColors.blue600,
                          ),
                        ),
                      ],
                    ),
            ),

            if (selectedMethod != null) ...[
              const SizedBox(height: 12),
              _buildPickupDetails(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPickupDetails() {
    switch (selectedMethod) {
      case PickupMethod.cod:
        return _buildCodDetails();

      case PickupMethod.selfPickup:
        return _buildSelfPickupDetails();

      case PickupMethod.instantCourier:
        return _buildInstantCourierDetails();

      case null:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCodDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lokasi Meetup'),
        const SizedBox(height: 8),
        TextFormField(
          controller: locationController,
          decoration: const InputDecoration(
            hintText: 'Masukkan lokasi meetup',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (selectedMethod != PickupMethod.cod) {
              return null;
            }

            if (value == null || value.trim().isEmpty) {
              return 'Lokasi meetup wajib diisi';
            }

            return null;
          },
        ),

        const SizedBox(height: 16),

        const Text('Tanggal dan Waktu Meetup'),
        const SizedBox(height: 8),
        TextFormField(
          controller: timeController,
          decoration: const InputDecoration(
            hintText: 'Pilih tanggal dan waktu',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (selectedMethod != PickupMethod.cod) {
              return null;
            }

            if (value == null || value.trim().isEmpty) {
              return 'Tanggal dan waktu wajib diisi';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSelfPickupDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lokasi Penjual'),
        const SizedBox(height: 8),
        const Text(
          'Jl. Bunga Coklat, Jatimulyo, '
          'Kec. Lowokwaru, Kota Malang',
        ),

        const SizedBox(height: 16),

        const Text('Tanggal dan Waktu Pengambilan'),
        const SizedBox(height: 8),
        TextFormField(
          controller: timeController,
          decoration: const InputDecoration(
            hintText: 'Pilih tanggal dan waktu',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (selectedMethod != PickupMethod.selfPickup) {
              return null;
            }

            if (value == null || value.trim().isEmpty) {
              return 'Tanggal dan waktu wajib diisi';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildInstantCourierDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Alamat Pengiriman'),
        const SizedBox(height: 8),
        TextFormField(
          controller: locationController,
          decoration: const InputDecoration(
            hintText: 'Masukkan alamat pengiriman',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (selectedMethod != PickupMethod.instantCourier) {
              return null;
            }

            if (value == null || value.trim().isEmpty) {
              return 'Alamat pengiriman wajib diisi';
            }

            return null;
          },
        ),
      ],
    );
  }
}
