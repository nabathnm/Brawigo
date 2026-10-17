import 'package:brawigo/features/order/data/review_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'review_event.dart';
import 'review_state.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  ReviewBloc(this._repository) : super(const ReviewInitial()) {
    on<ReviewLoadRequested>(_onLoadRequested);
    on<ReviewSubmitRequested>(_onSubmitRequested);
  }

  final ReviewRepository _repository;

  Future<void> _onLoadRequested(
    ReviewLoadRequested event,
    Emitter<ReviewState> emit,
  ) async {
    emit(const ReviewLoading());

    try {
      final data = await _repository.getReviewData(event.orderId);

      emit(
        ReviewLoaded(
          order: data['order'] as Map<String, dynamic>,
          review: data['review'] as Map<String, dynamic>?,
        ),
      );
    } catch (e) {
      emit(ReviewFailure(_messageFrom(e)));
    }
  }

  Future<void> _onSubmitRequested(
    ReviewSubmitRequested event,
    Emitter<ReviewState> emit,
  ) async {
    emit(const ReviewSubmitting());

    try {
      await _repository.submitReview(
        orderId: event.orderId,
        rating: event.rating,
        comment: event.comment,
      );

      emit(const ReviewSubmitSuccess());
    } catch (e) {
      emit(ReviewFailure(_messageFrom(e)));
    }
  }

  String _messageFrom(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
