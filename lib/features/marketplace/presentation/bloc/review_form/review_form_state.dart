import 'package:equatable/equatable.dart';

abstract class ReviewFormState extends Equatable {
  const ReviewFormState();

  @override
  List<Object?> get props => [];
}

class ReviewFormInitial extends ReviewFormState {
  const ReviewFormInitial();
}

class ReviewFormSubmitting extends ReviewFormState {
  const ReviewFormSubmitting();
}

class ReviewFormSubmitted extends ReviewFormState {
  const ReviewFormSubmitted();
}

class ReviewFormFailure extends ReviewFormState {
  const ReviewFormFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
