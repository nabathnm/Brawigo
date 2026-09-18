import 'package:equatable/equatable.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderEmpty extends OrderState {}

class OrderCreated extends OrderState {
  final String orderId;
  const OrderCreated(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class OrderSuccess extends OrderState {
  final String? message;
  const OrderSuccess({this.message});
  
  @override
  List<Object?> get props => [message];
}

class OrdersLoaded extends OrderState {
  final List<Map<String, dynamic>> orders;
  const OrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class OrderDetailLoaded extends OrderState {
  final Map<String, dynamic> order;
  const OrderDetailLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}
