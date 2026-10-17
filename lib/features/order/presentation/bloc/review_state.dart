import 'package:equatable/equatable.dart';

abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {
  const ReviewInitial();
}

class ReviewLoading extends ReviewState {
  const ReviewLoading();
}

class ReviewLoaded extends ReviewState {
  const ReviewLoaded({required this.order, required this.review});

  final Map<String, dynamic> order;
  final Map<String, dynamic>? review;

  bool get alreadyReviewed => review != null;

  @override
  List<Object?> get props => [order, review];
}

class ReviewSubmitting extends ReviewState {
  const ReviewSubmitting();
}

class ReviewSubmitSuccess extends ReviewState {
  const ReviewSubmitSuccess();
}

class ReviewFailure extends ReviewState {
  const ReviewFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
