import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'marketplace_event.dart';
import 'marketplace_state.dart';

class MarketplaceBloc extends Bloc<MarketplaceEvent, MarketplaceState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  MarketplaceBloc() : super(MarketplaceInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<LoadSellerProducts>(_onLoadSellerProducts);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<LoadProductImages>(_onLoadProductImages);
  }

  Future<void> _onLoadSellerProducts(
    LoadSellerProducts event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(MarketplaceLoading());
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User belum login");

      final response = await _supabase
          .from('products')
          .select()
          .eq('seller_id', user.id)
          .order('created_at', ascending: false);

      final products = List<Map<String, dynamic>>.from(response);
      emit(MarketplaceLoaded(products: products));
    } catch (e) {
      emit(
        MarketplaceError(
          message: 'Gagal memuat produk seller: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(MarketplaceLoading());
    try {
      final response = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      final products = List<Map<String, dynamic>>.from(response);
      emit(MarketplaceLoaded(products: products));
    } catch (e) {
      emit(MarketplaceError(message: 'Gagal memuat produk: ${e.toString()}'));
    }
  }

  Future<void> _onAddProduct(
    AddProduct event,
    Emitter<MarketplaceState> emit,
  ) async {
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
          final uniqueId = DateTime.now().microsecondsSinceEpoch;
          final fileName = '$uniqueId.$fileExt';

          await _supabase.storage
              .from('product_images')
              .uploadBinary(
                fileName,
                bytes,
                fileOptions: FileOptions(contentType: 'image/$fileExt'),
              );

          final imageUrl = _supabase.storage
              .from('product_images')
              .getPublicUrl(fileName);

          uploadedImagesData.add({'url': imageUrl, 'path': fileName});
        }
      }

      // 2. Insert data ke tabel products
      final productResponse = await _supabase
          .from('products')
          .insert({
            'product_name': event.name,
            'description': event.description,
            'price': event.price,
            'seller_id': user.id,
            'category_id': event.categoryId,
            'stock': event.stock,
            'status': 'active',
            'moderation_status': 'pending',
            if (uploadedImagesData.isNotEmpty)
              'thumbnail_url': uploadedImagesData.first['url'],
          })
          .select('id')
          .single();

      final newProductId = productResponse['id'];

      // 3. Insert semua gambar ke tabel product_images
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

  Future<void> _onUpdateProduct(
    UpdateProduct event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(MarketplaceLoading());
    try {
      // 1. Hapus gambar yang ditandai dihapus dari Storage
      for (final path in event.imagePathsToDelete) {
        if (path.isNotEmpty) {
          try {
            await _supabase.storage.from('product_images').remove([path]);
          } catch (_) {
            // Abaikan jika gagal (file mungkin sudah tidak ada)
          }
        }
      }

      // 2. Hapus record product_images yang dihapus dari DB
      if (event.imageIdsToDelete.isNotEmpty) {
        await _supabase
            .from('product_images')
            .delete()
            .inFilter('id', event.imageIdsToDelete);
      }

      // 3. Upload gambar-gambar baru & insert ke product_images
      // Ambil image_order tertinggi yang masih ada
      final existingImages = await _supabase
          .from('product_images')
          .select('image_order')
          .eq('product_id', event.id)
          .order('image_order', ascending: false)
          .limit(1);

      int nextOrder = existingImages.isNotEmpty
          ? ((existingImages.first['image_order'] as int?) ?? 0) + 1
          : 1;

      String? firstNewImageUrl;

      for (final xfile in event.newImages) {
        final bytes = await xfile.readAsBytes();
        final fileExt = xfile.name.split('.').last.toLowerCase();
        final fileName =
            'products/${event.id}/${DateTime.now().millisecondsSinceEpoch}_$nextOrder.$fileExt';

        await _supabase.storage
            .from('product_images')
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(contentType: 'image/$fileExt'),
            );
        final url = _supabase.storage
            .from('product_images')
            .getPublicUrl(fileName);

        await _supabase.from('product_images').insert({
          'product_id': event.id,
          'image_url': url,
          'image_path': fileName,
          'image_order': nextOrder,
        });

        firstNewImageUrl ??= url;
        nextOrder++;
      }

      // 4. Tentukan thumbnail_url = gambar pertama (image_order terendah) yang tersisa
      String? thumbnailUrl;
      if (firstNewImageUrl != null || event.imageIdsToDelete.isNotEmpty) {
        final allImages = await _supabase
            .from('product_images')
            .select('image_url, image_order')
            .eq('product_id', event.id)
            .order('image_order', ascending: true)
            .limit(1);
        thumbnailUrl = allImages.isNotEmpty
            ? allImages.first['image_url'] as String?
            : null;
      }

      // 5. Update data produk di tabel products
      await _supabase
          .from('products')
          .update({
            'product_name': event.name,
            'description': event.description,
            'price': event.price,
            if (event.stock != null) 'stock': event.stock,
            if (event.categoryId != null) 'category_id': event.categoryId,
            if (event.condition != null) 'condition': event.condition,
            if (event.pickupLocation != null)
              'pickup_location': event.pickupLocation,
            if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
          })
          .eq('id', event.id);

      // 6. Muat ulang produk
      add(LoadProducts());
    } catch (e) {
      emit(MarketplaceError(message: 'Gagal mengubah produk: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(MarketplaceLoading());

    try {
      // Ambil lokasi gambar sebelum produk dihapus.
      final images = await _supabase
          .from('product_images')
          .select('image_path')
          .eq('product_id', event.id);

      final imagePaths = images
          .map((image) => image['image_path']?.toString() ?? '')
          .where((path) => path.isNotEmpty)
          .toSet()
          .toList();

      // Hapus produk satu kali.
      final deletedProducts = await _supabase
          .from('products')
          .delete()
          .eq('id', event.id)
          .select('id');

      if (deletedProducts.isEmpty) {
        throw Exception(
          'Produk tidak ditemukan atau tidak memiliki izin untuk dihapus.',
        );
      }

      // Hapus file gambar dari Storage.
      if (imagePaths.isNotEmpty) {
        try {
          await _supabase.storage.from('product_images').remove(imagePaths);
        } catch (e) {
          // Penghapusan produk sudah berhasil.
          // Kegagalan menghapus gambar tidak membatalkan penghapusan.
          print('Gagal menghapus gambar: $e');
        }
      }

      emit(MarketplaceDeleteSuccess(message: 'Produk berhasil dihapus'));

      // Muat ulang daftar produk seller.
      add(LoadSellerProducts());
    } catch (e) {
      emit(
        MarketplaceError(message: 'Gagal menghapus produk: ${e.toString()}'),
      );
    }

    Future<void> _onLoadProductImages(
      LoadProductImages event,
      Emitter<MarketplaceState> emit,
    ) async {
      emit(ProductImagesLoading());

      try {
        final response = await _supabase
            .from('product_images')
            .select('image_url')
            .eq('product_id', event.productId)
            .order('image_order', ascending: true);

        final images = (response as List)
            .map((item) => item['image_url'].toString())
            .toList();

        emit(ProductImagesLoaded(images: images));
      } catch (e) {
        emit(ProductImagesError(message: e.toString()));
      }
    }
  }

  FutureOr<void> _onLoadProductImages(
    LoadProductImages event,
    Emitter<MarketplaceState> emit,
  ) {}
}
