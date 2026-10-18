import 'package:equatable/equatable.dart';

abstract class ReviewFormEvent extends Equatable {
  const ReviewFormEvent();

  @override
  List<Object?> get props => [];
}

class SubmitReviewRequested extends ReviewFormEvent {
  const SubmitReviewRequested({
    required this.orderId,
    required this.rating,
    required this.comment,
  });

  final String orderId;
  final int rating;
  final String comment;

  @override
  List<Object?> get props => [orderId, rating, comment];
}
