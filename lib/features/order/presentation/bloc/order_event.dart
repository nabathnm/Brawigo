import 'package:equatable/equatable.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrderDetails extends OrderEvent {
  final String orderId;
  const LoadOrderDetails(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class CreateOrder extends OrderEvent {
  final String productId;
  final int quantity;
  final String paymentMethod;
  final String meetupLocation;
  final String meetupTime;

  const CreateOrder({
    required this.productId,
    required this.quantity,
    required this.paymentMethod,
    required this.meetupLocation,
    required this.meetupTime,
  });

  @override
  List<Object?> get props => [productId, quantity, paymentMethod, meetupLocation, meetupTime];
}

class LoadBuyerOrders extends OrderEvent {}

class LoadSellerOrders extends OrderEvent {}

class UpdateOrderStatus extends OrderEvent {
  final String orderId;
  final String status;

  const UpdateOrderStatus({required this.orderId, required this.status});

  @override
  List<Object?> get props => [orderId, status];
}

class ConfirmPayment extends OrderEvent {
  final String orderId;
  final bool isConfirmed;

  const ConfirmPayment({required this.orderId, required this.isConfirmed});

  @override
  List<Object?> get props => [orderId, isConfirmed];
}
