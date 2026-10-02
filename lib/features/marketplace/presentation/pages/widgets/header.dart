import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Header extends StatefulWidget {
  final VoidCallback? onRoleSwitch;

  const Header({super.key, this.onRoleSwitch});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  final _supabase = Supabase.instance.client;
  String _displayName = 'Pengguna';
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await _supabase
          .from('profiles')
          .select('full_name, username, profile_photo_url')
          .eq('id', user.id)
          .maybeSingle();

      if (res != null && mounted) {
        final username = res['username']?.toString().trim();
        final fullName = res['full_name']?.toString().trim();
        final photo = res['profile_photo_url']?.toString().trim();

        setState(() {
          if (username != null && username.isNotEmpty && username != '-') {
            _displayName = username;
          } else if (fullName != null && fullName.isNotEmpty) {
            _displayName = fullName;
          } else {
            _displayName = user.email?.split('@').first ?? 'Pengguna';
          }
          _photoUrl = photo;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF4A7EBB),
                backgroundImage: (_photoUrl != null && _photoUrl!.isNotEmpty)
                    ? NetworkImage(_photoUrl!)
                    : null,
                child: (_photoUrl == null || _photoUrl!.isEmpty)
                    ? Text(
                        _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Selamat Datang,",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  _displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: BrawigoColors.primary950,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BrawigoColors.primary200, width: 1),
          ),
          child: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'buyer') {
                widget.onRoleSwitch?.call();
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            offset: const Offset(0, 40),
            color: Colors.white,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    "Seller",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: BrawigoColors.primary950,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: BrawigoColors.primary950,
                  ),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'buyer',
                child: Text(
                  'Buyer',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
