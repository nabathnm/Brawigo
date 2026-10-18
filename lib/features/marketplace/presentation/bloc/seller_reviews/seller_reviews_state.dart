import 'package:equatable/equatable.dart';

abstract class SellerReviewsState extends Equatable {
  const SellerReviewsState();

  @override
  List<Object?> get props => [];
}

class SellerReviewsInitial extends SellerReviewsState {
  const SellerReviewsInitial();
}

class SellerReviewsLoading extends SellerReviewsState {
  const SellerReviewsLoading();
}

class SellerReviewsLoaded extends SellerReviewsState {
  const SellerReviewsLoaded(this.reviews);

  final List<Map<String, dynamic>> reviews;

  double get averageRating {
    if (reviews.isEmpty) return 0;
    final total = reviews.fold<double>(0, (sum, review) {
      final value = review['rating'];
      return sum +
          (value is num ? value.toDouble() : double.tryParse('$value') ?? 0);
    });
    return total / reviews.length;
  }

  @override
  List<Object?> get props => [reviews];
}

class SellerReviewsFailure extends SellerReviewsState {
  const SellerReviewsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
