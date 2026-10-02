import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  OrderBloc() : super(OrderInitial()) {
    on<CreateOrder>(_onCreateOrder);
    on<LoadBuyerOrders>(_onLoadBuyerOrders);
    on<LoadSellerOrders>(_onLoadSellerOrders);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<ConfirmPayment>(_onConfirmPayment);
  }

  Future<void> _onCreateOrder(CreateOrder event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        emit(const OrderError('User belum login.'));
        return;
      }

      final product = await _supabase
          .from('products')
          .select()
          .eq('id', event.productId)
          .single();

      if (product['seller_id'] == user.id) {
        emit(const OrderError('Tidak dapat membeli produk sendiri.'));
        return;
      }
      
      if ((product['stock'] as num) < event.quantity) {
        emit(const OrderError('Stok tidak mencukupi.'));
        return;
      }

      final double unitPrice = (product['price'] as num).toDouble();
      final double totalAmount = unitPrice * event.quantity;

      await _supabase.from('orders').insert({
        'buyer_id': user.id,
        'seller_id': product['seller_id'],
        'product_id': event.productId,
        'product_name_snapshot': product['product_name'],
        'product_price_snapshot': unitPrice,
        'thumbnail_url_snapshot': product['thumbnail_url'],
        'quantity': event.quantity,
        'total_amount': totalAmount,
        'payment_method': event.paymentMethod,
        'order_status': 'created',
        'payment_status': event.paymentMethod.toLowerCase() == 'cod' ? 'cod_payment' : 'pending',
        'meetup_location': event.meetupLocation,
        'meetup_time': event.meetupTime,
        'created_at': DateTime.now().toIso8601String(),
      });

      emit(const OrderSuccess(message: 'Pesanan berhasil dibuat!'));
    } catch (e) {
      emit(OrderError('Gagal membuat order: ${e.toString()}'));
    }
  }

  Future<void> _onLoadBuyerOrders(LoadBuyerOrders event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        emit(const OrderError('User belum login.'));
        return;
      }

      final response = await _supabase
          .from('orders')
          .select()
          .eq('buyer_id', user.id)
          .order('created_at', ascending: false);

      final orders = List<Map<String, dynamic>>.from(response);
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrderError('Gagal mengambil order: ${e.toString()}'));
    }
  }

  Future<void> _onLoadSellerOrders(LoadSellerOrders event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        emit(const OrderError('User belum login.'));
        return;
      }

      final response = await _supabase
          .from('orders')
          .select()
          .eq('seller_id', user.id)
          .order('created_at', ascending: false);

      final orders = List<Map<String, dynamic>>.from(response);
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrderError('Gagal mengambil order seller: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateOrderStatus(UpdateOrderStatus event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final orderRes = await _supabase
          .from('orders')
          .select()
          .eq('id', event.orderId)
          .single();

      if (orderRes['order_status'] == 'completed') {
        emit(const OrderError('Order yang sudah selesai tidak dapat diubah.'));
        return;
      }

      if (orderRes['order_status'] == 'cancelled') {
        emit(const OrderError('Order yang sudah dibatalkan tidak dapat dilanjutkan.'));
        return;
      }

      await _supabase
          .from('orders')
          .update({'order_status': event.status})
          .eq('id', event.orderId);

      emit(const OrderSuccess(message: 'Status pesanan berhasil diperbarui.'));
    } catch (e) {
      emit(OrderError('Gagal mengubah status order: ${e.toString()}'));
    }
  }

  Future<void> _onConfirmPayment(ConfirmPayment event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final orderRes = await _supabase
          .from('orders')
          .select('order_status')
          .eq('id', event.orderId)
          .single();

      if (orderRes['order_status'] == 'completed') {
        emit(const OrderError('Order yang sudah selesai tidak dapat diubah.'));
        return;
      }

      if (orderRes['order_status'] == 'cancelled') {
        emit(const OrderError('Order yang sudah dibatalkan tidak dapat dilanjutkan.'));
        return;
      }

      final newPaymentStatus = event.isConfirmed ? 'paid' : 'rejected';
      final newOrderStatus = event.isConfirmed ? 'confirmed' : 'cancelled';

      await _supabase
          .from('orders')
          .update({
            'payment_status': newPaymentStatus,
            'order_status': newOrderStatus,
          })
          .eq('id', event.orderId);

      emit(OrderSuccess(message: event.isConfirmed ? 'Pembayaran diterima.' : 'Pembayaran ditolak.'));
    } catch (e) {
      emit(OrderError('Gagal memproses konfirmasi pembayaran: ${e.toString()}'));
    }
  }
}
