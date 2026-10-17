import 'package:equatable/equatable.dart';

abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

class ReviewLoadRequested extends ReviewEvent {
  const ReviewLoadRequested(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class ReviewSubmitRequested extends ReviewEvent {
  const ReviewSubmitRequested({
    required this.orderId,
    required this.rating,
    this.comment,
  });

  final String orderId;
  final int rating;
  final String? comment;

  @override
  List<Object?> get props => [orderId, rating, comment];
}
