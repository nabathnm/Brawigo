import 'package:equatable/equatable.dart';

abstract class SellerReviewsEvent extends Equatable {
  const SellerReviewsEvent();

  @override
  List<Object?> get props => [];
}

class SellerReviewsRequested extends SellerReviewsEvent {
  const SellerReviewsRequested(this.sellerId);

  final String sellerId;

  @override
  List<Object?> get props => [sellerId];
}
