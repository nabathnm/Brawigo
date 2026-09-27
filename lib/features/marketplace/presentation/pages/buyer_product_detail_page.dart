import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart'; 
import 'package:brawigo/features/chat/presentation/pages/chat_room_page.dart';

class BuyerProductDetailPage extends StatefulWidget {
  final Map<String, String> product;

  const BuyerProductDetailPage({super.key, required this.product});

  @override
  State<BuyerProductDetailPage> createState() => _BuyerProductDetailPageState();
}

class _BuyerProductDetailPageState extends State<BuyerProductDetailPage> {
  int _currentImageIndex = 0;
  bool _isDescriptionExpanded = false;
  List<String> _images = [];
  bool _isLoadingImages = true;

  @override
  void initState() {
    super.initState();
    _fetchImages();
    _saveToRecentlyViewed();
  }

  Future<void> _saveToRecentlyViewed() async {
    final productId = widget.product['id'];
    if (productId != null && productId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      List<String> viewed = prefs.getStringList('recently_viewed') ?? [];
      viewed.remove(productId);
      viewed.add(productId);
      if (viewed.length > 10) {
        viewed.removeAt(0);
      }
      await prefs.setStringList('recently_viewed', viewed);
    }
  }

  Future<void> _openChat() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final product = widget.product;
    final sellerId = product['seller_id'] ?? '';
    final productId = product['id'] ?? '';

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu untuk memulai chat.')),
      );
      return;
    }

    if (sellerId.isEmpty || productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informasi produk/penjual tidak lengkap.')),
      );
      return;
    }

    if (currentUser.id == sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ini adalah produk Anda sendiri.')),
      );
      return;
    }

    try {
      final existing = await Supabase.instance.client
          .from('conversations')
          .select('id')
          .eq('buyer_id', currentUser.id)
          .eq('seller_id', sellerId)
          .eq('product_id', productId)
          .maybeSingle();

      String conversationId;
      bool isNew = false;

      if (existing != null) {
        conversationId = existing['id'];
      } else {
        final created = await Supabase.instance.client
            .from('conversations')
            .insert({
              'buyer_id': currentUser.id,
              'seller_id': sellerId,
              'product_id': productId,
            })
            .select('id')
            .single();
        conversationId = created['id'];
        isNew = true;
      }

      final sellerProfile = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', sellerId)
          .maybeSingle();
      final sellerName = sellerProfile?['full_name'] ?? 'Penjual';

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomPage(
            conversationId: conversationId,
            otherUserName: sellerName,
            otherUserId: sellerId,
            productData: widget.product,
            sendProductMention: isNew,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka chat: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _fetchImages() async {
    final productId = widget.product['id'];
    if (productId != null && productId.isNotEmpty) {
      final response = await Supabase.instance.client
          .from('product_images')
          .select('image_url')
          .eq('product_id', productId)
          .order('image_order', ascending: true);
      
      final List<String> fetchedImages = (response as List).map((e) => e['image_url'] as String).toList();
      
      if (mounted) {
        setState(() {
          if (fetchedImages.isNotEmpty) {
            _images = fetchedImages;
          } else {
            final thumb = widget.product['image_url'];
            if (thumb != null && thumb.isNotEmpty) _images = [thumb];
          }
          _isLoadingImages = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          final thumb = widget.product['image_url'];
          if (thumb != null && thumb.isNotEmpty) _images = [thumb];
          _isLoadingImages = false;
        });
      }
    }
  }

  bool get _isLongDescription {
    final desc = widget.product['description'] ?? "";
    return desc.length > 120;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 380,
                  width: double.infinity,
                  child: _isLoadingImages
                      ? Container(
                          color: Colors.grey.shade200,
                          child: const Center(child: CircularProgressIndicator()),
                        )
                      : (_images.isNotEmpty)
                          ? PageView.builder(
                              itemCount: _images.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return Image.network(
                                  _images[index],
                                  width: double.infinity,
                                  height: 380,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 380,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                            ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                if (_images.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "${_currentImageIndex + 1}/${_images.length}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15243C),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Rice Cooker Mikoya',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B5F9E), 
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product['price'] ?? 'Rp200.000',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF15243C),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:  BrawigoColors.blue50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: BrawigoColors.blue400,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FutureBuilder(
                                future: Supabase.instance.client
                                    .from('profiles')
                                    .select('full_name')
                                    .eq('id', product['seller_id'] ?? '')
                                    .maybeSingle(),
                                builder: (context, snapshot) {
                                  String sellerName = "Memuat...";
                                  if (snapshot.connectionState == ConnectionState.done) {
                                    if (snapshot.hasData && snapshot.data != null) {
                                      sellerName = (snapshot.data as Map)['full_name'] ?? 'Penjual Tidak Diketahui';
                                    } else {
                                      sellerName = 'Penjual Tidak Diketahui';
                                    }
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sellerName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF15243C),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Text(
                                        "Aktif baru saja",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color.fromARGB(255, 9, 9, 9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A7EBB),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(0, 36),
                              ),
                              child: const Text(
                                "Kunjungi Toko",
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
                          children: [
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                                children: [
                                  TextSpan(
                                    text: "12 ",
                                    style: TextStyle(
                                      color: Color(0xFF2B5F9E),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: "Produk"),
                                ],
                              ),
                            ),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                                children: [
                                  TextSpan(
                                    text: "4.9 ",
                                    style: TextStyle(
                                      color: Color(0xFF2B5F9E),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: "Penilaian"),
                                ],
                              ),
                            ),
                            Row(
                              children: const [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Color(0xFF475569),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Tlogomas, Malang",
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
                  const SizedBox(height: 24),

                  const Text(
                    "Deskripsi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF15243C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    (product['description'] != null && product['description']!.isNotEmpty)
                        ? product['description']!
                        : "Tidak ada deskripsi untuk produk ini.",
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF334155),
                    ),
                    maxLines: _isDescriptionExpanded ? null : (_isLongDescription ? 3 : null),
                    overflow: _isDescriptionExpanded ? TextOverflow.visible : (_isLongDescription ? TextOverflow.ellipsis : TextOverflow.visible),
                  ),
                  if (_isLongDescription) const SizedBox(height: 16),
                  if (_isLongDescription)
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isDescriptionExpanded ? "Tutup Selengkapnya" : "Lihat Selengkapnya",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isDescriptionExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: const Color(0xFF334155),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [

                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF2B5F9E),
                      width: 1.5,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Color(0xFF2B5F9E),
                      size: 22,
                    ),
                    onPressed: _openChat,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A7EBB),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      "Checkout",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
