import 'package:flutter/material.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import '../models/pickup_method.dart';

class NoteInput extends StatelessWidget {
  const NoteInput({super.key});
  @override
  Widget build(BuildContext context) {
    final _locationController = TextEditingController();

    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          color: Color(0Xffffffff),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Image.asset("assets/icons/marketplace/note.png"),
                SizedBox(width: 8),
                Text(
                  "Catatan untuk Penjual",
                  style: TextStyle(
                    color: BrawigoColors.blue800,
                    fontWeight: .w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: BrawigoColors.blue800,
              ),
              decoration: InputDecoration(
                hintText: 'Tulis catatan...',
                hintStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: const Color(0xff20395A).withValues(alpha: 0.35),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
