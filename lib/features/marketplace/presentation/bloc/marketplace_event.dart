import 'package:image_picker/image_picker.dart';

abstract class MarketplaceEvent {}

class LoadProducts extends MarketplaceEvent {}

class AddProduct extends MarketplaceEvent {
  final String name;
  final String description;
  final double price;
  final int stock;
  final String categoryId;
  final String condition;
  final String? pickupLocation;
  final List<XFile>? images;

  AddProduct({
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.condition,
    this.pickupLocation,
    this.images,
  });
}

class UpdateProduct extends MarketplaceEvent {
  final String id;
  final String name;
  final String description;
  final double price;
  final int? stock;
  final String? categoryId;
  final String? condition;
  final String? pickupLocation;
  final XFile? newImage;
  final String? oldImageUrl;

  UpdateProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.stock,
    this.categoryId,
    this.condition,
    this.pickupLocation,
    this.newImage,
    this.oldImageUrl,
  });
}

class DeleteProduct extends MarketplaceEvent {
  final String id;
  final String? imageUrl;

  DeleteProduct({required this.id, this.imageUrl});
}
