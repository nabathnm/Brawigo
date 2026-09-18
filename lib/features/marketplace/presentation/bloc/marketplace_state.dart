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
