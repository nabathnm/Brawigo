abstract class MarketplaceState {}

class MarketplaceInitial extends MarketplaceState {}

class MarketplaceLoading extends MarketplaceState {}

class MarketplaceLoaded extends MarketplaceState {
  final List<Map<String, dynamic>> products;

  MarketplaceLoaded({required this.products});
}

class MarketplaceError extends MarketplaceState {
  final String message;

  MarketplaceError({required this.message});
}

class MarketplaceDeleteSuccess extends MarketplaceState {
  final String message;

  MarketplaceDeleteSuccess({required this.message});
}

class ProductImagesLoading extends MarketplaceState {}

class ProductImagesLoaded extends MarketplaceState {
  final List<String> images;

  ProductImagesLoaded({required this.images});
}

class ProductImagesError extends MarketplaceState {
  final String message;

  ProductImagesError({required this.message});
}
