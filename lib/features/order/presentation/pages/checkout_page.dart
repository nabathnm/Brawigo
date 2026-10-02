import 'package:brawigo/features/order/presentation/pages/models/payment_method.dart';
import 'package:brawigo/features/order/presentation/pages/models/pickup_method.dart';
import 'package:brawigo/features/order/presentation/pages/widgets/checkout_button.dart';
import 'package:brawigo/features/order/presentation/pages/widgets/checkout_product_card.dart';
import 'package:brawigo/features/order/presentation/pages/widgets/note_input.dart';
import 'package:brawigo/features/order/presentation/pages/widgets/order_summary.dart';
import 'package:brawigo/features/order/presentation/pages/widgets/payment_method_bottom_sheet.dart';
import 'package:brawigo/features/order/presentation/pages/widgets/payment_method_selector.dart';
import 'package:brawigo/features/order/presentation/pages/widgets/pickup_method_bottom_sheet.dart';
import 'package:brawigo/features/order/presentation/pages/widgets/pickup_method_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:brawigo/core/utils/constants/brawigo_colors.dart';

import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';

class CheckoutPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> product;

  const CheckoutPage({
    super.key,
    required this.productId,
    required this.product,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  final _locationController = TextEditingController();
  final _paymentController = TextEditingController();
  final _timeController = TextEditingController();

  final int _quantity = 1;

  PickupMethod? _deliverMethod;
  PaymentMethod? _paymentMethod;

  @override
  void dispose() {
    _locationController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _showMethodPicker() async {
    final result = await showModalBottomSheet<PickupMethod>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const PickupMethodBottomSheet(),
    );

    if (result != null) {
      setState(() {
        _deliverMethod = result;
      });
    }
  }

  Future<void> _showMethodPayment() async {
    final result = await showModalBottomSheet<PaymentMethod>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const PaymentMethodBottomSheet(),
    );

    if (result != null) {
      setState(() {
        _paymentMethod = result;
      });
    }
  }

  void _createOrder() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<OrderBloc>().add(
      CreateOrder(
        productId: widget.productId,
        quantity: _quantity,
        paymentMethod: _paymentController.text,
        meetupLocation: _locationController.text,
        meetupTime: _timeController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'Pesanan berhasil dibuat!'),
            ),
          );

          Navigator.pop(context);
        }

        if (state is OrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: BrawigoColors.blue100,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.asset("./assets/icons/common/arrow_back.png"),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Checkout",
                style: TextStyle(
                  fontSize: 20,
                  color: BrawigoColors.blue800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "Periksa kembali pesanan kamu",
                style: TextStyle(fontSize: 12, color: BrawigoColors.blue800),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckoutProductCard(
                  product: widget.product,
                  productName: widget.product['product_name'] ?? 'Produk',
                  price: (widget.product['price'] as num?) ?? 0,
                ),

                const SizedBox(height: 12),

                PickupMethodSelector(
                  selectedMethod: _deliverMethod,
                  onTap: _showMethodPicker,
                ),

                const SizedBox(height: 12),

                PaymentMethodSelector(
                  selectedMethod: _paymentMethod,
                  onTap: _showMethodPayment,
                ),

                const SizedBox(height: 12),

                NoteInput(),

                const SizedBox(height: 12),

                OrderSummary(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        bottomNavigationBar: CheckoutButton(onSubmit: _createOrder),
      ),
    );
  }
}
