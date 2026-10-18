import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/review_repository.dart';
import 'review_form_event.dart';
import 'review_form_state.dart';

class ReviewFormBloc extends Bloc<ReviewFormEvent, ReviewFormState> {
  ReviewFormBloc({required ReviewRepository repository})
      : _repository = repository,
        super(const ReviewFormInitial()) {
    on<SubmitReviewRequested>(_onSubmitReviewRequested);
  }

  final ReviewRepository _repository;

  Future<void> _onSubmitReviewRequested(
    SubmitReviewRequested event,
    Emitter<ReviewFormState> emit,
  ) async {
    emit(const ReviewFormSubmitting());
    try {
      await _repository.submitReview(
        orderId: event.orderId,
        rating: event.rating,
        comment: event.comment,
      );
      emit(const ReviewFormSubmitted());
    } catch (error) {
      emit(ReviewFormFailure(_readableError(error)));
    }
  }

  String _readableError(Object error) {
    if (error is ReviewRepositoryException) return error.message;
    // PostgREST/Supabase errors can contain useful constraint or policy details.
    return 'Gagal mengirim ulasan. Periksa koneksi lalu coba lagi.';
  }
}
