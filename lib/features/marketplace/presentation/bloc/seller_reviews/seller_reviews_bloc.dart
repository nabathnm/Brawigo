import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/seller_reviews_repository.dart';
import 'seller_reviews_event.dart';
import 'seller_reviews_state.dart';

class SellerReviewsBloc extends Bloc<SellerReviewsEvent, SellerReviewsState> {
  SellerReviewsBloc({required SellerReviewsRepository repository})
    : _repository = repository,
      super(const SellerReviewsInitial()) {
    on<SellerReviewsRequested>(_onRequested);
  }

  final SellerReviewsRepository _repository;

  Future<void> _onRequested(
    SellerReviewsRequested event,
    Emitter<SellerReviewsState> emit,
  ) async {
    emit(const SellerReviewsLoading());

    try {
      final reviews = await _repository.fetchSellerReviews(event.sellerId);
      emit(SellerReviewsLoaded(reviews));
    } catch (e, stackTrace) {
      debugPrint('Gagal memuat ulasan toko: $e');
      debugPrintStack(stackTrace: stackTrace);

      emit(SellerReviewsFailure('Gagal memuat ulasan toko: $e'));
    }
  }
}
