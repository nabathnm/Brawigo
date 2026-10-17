import 'package:brawigo/features/order/data/review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/review_bloc.dart';
import '../bloc/review_event.dart';
import '../bloc/review_state.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ReviewBloc(ReviewRepository())..add(ReviewLoadRequested(orderId)),
      child: _ReviewView(orderId: orderId),
    );
  }
}

class _ReviewView extends StatefulWidget {
  const _ReviewView({required this.orderId});

  final String orderId;

  @override
  State<_ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<_ReviewView> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Produk')),
      body: BlocConsumer<ReviewBloc, ReviewState>(
        listener: (context, state) {
          if (state is ReviewSubmitSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Review berhasil dikirim.')),
            );
            Navigator.pop(context, true);
          }

          if (state is ReviewFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is ReviewInitial || state is ReviewLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ReviewSubmitting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Mengirim review...'),
                ],
              ),
            );
          }

          if (state is ReviewFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ReviewBloc>().add(
                          ReviewLoadRequested(widget.orderId),
                        );
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is ReviewLoaded) {
            final order = state.order;
            final existingReview = state.review;

            if (state.alreadyReviewed) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Pesanan ini sudah direview.',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text('Rating: ${existingReview?['rating'] ?? '-'} / 5'),
                      if ((existingReview?['comment'] ?? '')
                          .toString()
                          .isNotEmpty)
                        Text(existingReview!['comment'].toString()),
                    ],
                  ),
                ),
              );
            }

            final productName = order['product_name_snapshot'] ?? 'Produk';

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  productName.toString(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Berikan rating',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final value = index + 1;

                    return IconButton(
                      tooltip: '$value bintang',
                      onPressed: () {
                        setState(() => _rating = value);
                      },
                      icon: Icon(
                        value <= _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                    );
                  }),
                ),
                Center(child: Text('$_rating dari 5 bintang')),
                const SizedBox(height: 24),
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Komentar (opsional)',
                    hintText: 'Ceritakan pengalamanmu...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    FocusScope.of(context).unfocus();

                    context.read<ReviewBloc>().add(
                      ReviewSubmitRequested(
                        orderId: widget.orderId,
                        rating: _rating,
                        comment: _commentController.text,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Kirim Review'),
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
