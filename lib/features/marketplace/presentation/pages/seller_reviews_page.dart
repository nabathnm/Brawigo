import 'package:brawigo/features/marketplace/data/repositories/seller_reviews_repository.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/seller_reviews/seller_reviews_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/seller_reviews/seller_reviews_event.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/seller_reviews/seller_reviews_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SellerReviewsPage extends StatelessWidget {
  const SellerReviewsPage({super.key, required this.sellerId});

  final String sellerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SellerReviewsBloc(repository: SellerReviewsRepository())
            ..add(SellerReviewsRequested(sellerId)),
      child: _SellerReviewsView(sellerId: sellerId),
    );
  }
}

class _SellerReviewsView extends StatelessWidget {
  const _SellerReviewsView({required this.sellerId});

  final String sellerId;

  String _reviewerName(Map<String, dynamic>? reviewer) {
    if (reviewer == null) return 'Pembeli';
    final fullName = reviewer['full_name']?.toString().trim() ?? '';
    final username = reviewer['username']?.toString().trim() ?? '';
    if (fullName.isNotEmpty) return fullName;
    if (username.isNotEmpty && username != '-') return username;
    return 'Pembeli';
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ulasan Toko'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF15243C),
        elevation: 0,
      ),
      body: BlocBuilder<SellerReviewsBloc, SellerReviewsState>(
        builder: (context, state) {
          if (state is SellerReviewsInitial || state is SellerReviewsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SellerReviewsFailure) {
            return _MessageState(
              icon: Icons.error_outline,
              message: state.message,
              actionLabel: 'Coba lagi',
              onAction: () => context.read<SellerReviewsBloc>().add(
                SellerReviewsRequested(sellerId),
              ),
            );
          }

          if (state is SellerReviewsLoaded) {
            final reviews = state.reviews;

            if (reviews.isEmpty) {
              return const _MessageState(
                icon: Icons.rate_review_outlined,
                message: 'Belum ada ulasan dari pembeli untuk toko ini.',
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF59E0B),
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${reviews.length} ulasan pembeli',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                for (final review in reviews)
                  _ReviewCard(
                    reviewerName: _reviewerName(
                      review['reviewer'] as Map<String, dynamic>?,
                    ),
                    photoUrl:
                        (review['reviewer']
                                as Map<String, dynamic>?)?['profile_photo_url']
                            ?.toString(),
                    productName:
                        ((review['product']
                                    as Map<
                                      String,
                                      dynamic
                                    >?)?['product_name'] ??
                                'Produk')
                            .toString(),
                    rating: review['rating'],
                    comment: review['comment']?.toString() ?? '',
                    date: _formatDate(review['created_at']),
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.reviewerName,
    required this.photoUrl,
    required this.productName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  final String reviewerName;
  final String? photoUrl;
  final String productName;
  final dynamic rating;
  final String comment;
  final String date;

  @override
  Widget build(BuildContext context) {
    final parsedRating = rating is num
        ? rating.toDouble()
        : double.tryParse('$rating') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE2E8F0),
                backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                    ? NetworkImage(photoUrl!)
                    : null,
                child: photoUrl == null || photoUrl!.isEmpty
                    ? Text(
                        reviewerName.isNotEmpty
                            ? reviewerName[0].toUpperCase()
                            : 'P',
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15243C),
                      ),
                    ),
                    Text(
                      productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (date.isNotEmpty)
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < parsedRating.round()
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: const Color(0xFFF59E0B),
                size: 18,
              ),
            ),
          ),
          if (comment.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
