import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'marketplace_event.dart';
import 'marketplace_state.dart';

class MarketplaceBloc extends Bloc<MarketplaceEvent, MarketplaceState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  MarketplaceBloc() : super(MarketplaceInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
  }

  Future<void> _onLoadProducts(LoadProducts event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      // Pastikan Anda sudah membuat tabel bernama 'products' di Supabase
      final response = await _supabase.from('products').select().order('created_at', ascending: false);
      
      final products = List<Map<String, dynamic>>.from(response);
      emit(MarketplaceLoaded(products: products));
    } catch (e) {
      emit(MarketplaceError(message: 'Gagal memuat produk: ${e.toString()}'));
    }
  }

  Future<void> _onAddProduct(AddProduct event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User belum login");

      List<Map<String, String>> uploadedImagesData = [];

      // 1. Upload semua file ke Supabase Storage
      if (event.images != null && event.images!.isNotEmpty) {
        for (var image in event.images!) {
          final bytes = await image.readAsBytes();
          final fileExt = image.name.split('.').last;
          // Buat nama unik per file agar tidak tertimpa
          final uniqueId = DateTime.now().microsecondsSinceEpoch;
          final fileName = '$uniqueId.$fileExt';
          
          await _supabase.storage.from('product_images').uploadBinary(
            fileName, 
            bytes,
            fileOptions: FileOptions(contentType: 'image/$fileExt'),
          );
          
          final imageUrl = _supabase.storage.from('product_images').getPublicUrl(fileName);
          
          uploadedImagesData.add({
            'url': imageUrl,
            'path': fileName,
          });
        }
      }

      // 2. Insert data ke Database (tabel products) dan ambil ID yang baru dibuat
      final productResponse = await _supabase.from('products').insert({
        'product_name': event.name,
        'description': event.description,
        'price': event.price,
        'seller_id': user.id,
        'category_id': event.categoryId,
        'condition': event.condition,
        'stock': event.stock,
        if (event.pickupLocation != null && event.pickupLocation!.isNotEmpty) 'pickup_location': event.pickupLocation,
        'status': 'active',
        'moderation_status': 'pending',
        if (uploadedImagesData.isNotEmpty) 'thumbnail_url': uploadedImagesData.first['url'],
      }).select('id').single();

      final newProductId = productResponse['id'];

      // 3. Insert semua gambar (termasuk thumbnail) ke tabel product_images
      if (uploadedImagesData.isNotEmpty) {
        final productImagesToInsert = <Map<String, dynamic>>[];
        for (int i = 0; i < uploadedImagesData.length; i++) {
          productImagesToInsert.add({
            'product_id': newProductId,
            'image_url': uploadedImagesData[i]['url'],
            'image_path': uploadedImagesData[i]['path'],
            'image_order': i + 1,
          });
        }
        await _supabase.from('product_images').insert(productImagesToInsert);
      }

      // 4. Muat ulang daftar produk
      add(LoadProducts());
    } catch (e) {
      emit(MarketplaceError(message: 'Gagal menambah produk: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProduct(UpdateProduct event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      String? imageUrl = event.oldImageUrl;

      // 1. Upload gambar baru jika ada
      if (event.newImage != null) {
        final bytes = await event.newImage!.readAsBytes();
        final fileExt = event.newImage!.name.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        
        await _supabase.storage.from('product_images').uploadBinary(
          fileName, 
          bytes,
          fileOptions: FileOptions(contentType: 'image/$fileExt'),
        );
        imageUrl = _supabase.storage.from('product_images').getPublicUrl(fileName);
        
        // (Opsional) Logika untuk menghapus gambar lama dari storage di sini jika diinginkan
      }

      // 2. Update data di Database
      await _supabase.from('products').update({
        'product_name': event.name,
        'description': event.description,
        'price': event.price,
        if (event.stock != null) 'stock': event.stock,
        if (event.categoryId != null) 'category_id': event.categoryId,
        if (event.condition != null) 'condition': event.condition,
        if (event.pickupLocation != null) 'pickup_location': event.pickupLocation,
        if (imageUrl != null) 'thumbnail_url': imageUrl,
      }).eq('id', event.id);

      // 3. Muat ulang produk
      add(LoadProducts());
    } catch (e) {
      emit(MarketplaceError(message: 'Gagal mengubah produk: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteProduct(DeleteProduct event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      // 1. Hapus gambar terkait dari Storage (jika ada)
      if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
        try {
          final fileName = event.imageUrl!.split('/').last;
          await _supabase.storage.from('product_images').remove([fileName]);
        } catch (_) {
          // Abaikan jika gagal hapus file dari storage (misal: file sudah dihapus atau tidak ditemukan)
        }
      }

      // 2. Hapus data dari Database
      await _supabase.from('products').delete().eq('id', event.id);

      // 3. Muat ulang produk
      add(LoadProducts());
    } catch (e) {
      emit(MarketplaceError(message: 'Gagal menghapus produk: ${e.toString()}'));
    }
  }
}
