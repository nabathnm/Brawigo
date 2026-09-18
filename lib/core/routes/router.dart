import 'package:brawigo/features/order/presentation/bloc/order_bloc.dart';
import 'package:brawigo/features/order/presentation/bloc/order_event.dart';
import 'package:brawigo/features/order/presentation/pages/checkout_page.dart';
import 'package:brawigo/features/order/presentation/pages/order_list_page.dart';
import 'package:brawigo/features/order/presentation/pages/order_detail_page.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/complete_profile_page.dart';
import '../../features/marketplace/presentation/pages/main_screen.dart';
import '../../features/auth/presentation/pages/set_photo_page.dart';
import '../../features/auth/presentation/pages/onboarding_success_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_event.dart';

final GoRouter appRouter = GoRouter(
  initialLocation : '/splash',
  debugLogDiagnostics: true,

  routes: [
    GoRoute(path: '/splash',builder: (context,state) => const SplashPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
  
    GoRoute(path: '/otp', builder: (context, state) {
      final email = (state.extra as String?) ?? '';
      return OtpPage(email:email);
    }),
    GoRoute(path: '/complete-profile', builder: (context, state) => const CompleteProfilePage()),
    GoRoute(
      path: '/set-photo',
      builder: (context, state) => const SetPhotoPage(),
    ),
    GoRoute(
      path: '/onboarding-success',
      builder: (context, state) => const OnboardingSuccessPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => BlocProvider(
        create: (context) => MarketplaceBloc()..add(LoadProducts()),
        child: const MainScreen(isSeller: false),
      ),
    ),
    GoRoute(
      path: '/buyer',
      builder: (context, state) => BlocProvider(
        create: (context) => MarketplaceBloc()..add(LoadProducts()),
        child: const MainScreen(isSeller: false),
      ),
    ),
    GoRoute(
      path: '/seller',
      builder: (context, state) {
        return BlocProvider(
          create: (context) => MarketplaceBloc()..add(LoadSellerProducts()),
          child: const MainScreen(isSeller: true),
        );
      },
    ),
    GoRoute(
      path: '/checkout/:productId',
      builder: (context, state) {
        final productId = state.pathParameters['productId']!;
        final product = state.extra as Map<String, dynamic>;
        return BlocProvider(
          create: (context) => OrderBloc(),
          child: CheckoutPage(productId: productId, product: product),
        );
      },
    ),
    GoRoute(
      path: '/order/:id',
      builder: (context, state) {
        final orderId = state.pathParameters['id']!;
        return BlocProvider(
          create: (context) => OrderBloc(),
          child: OrderDetailPage(orderId: orderId),
        );
      },
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => BlocProvider(
        create: (context) => OrderBloc()..add(LoadBuyerOrders()),
        child: const OrderListPage(isSeller: false),
      ),
    ),
    GoRoute(
      path: '/seller/orders',
      builder: (context, state) => BlocProvider(
        create: (context) => OrderBloc()..add(LoadSellerOrders()),
        child: const OrderListPage(isSeller: true),
      ),
    ),
    GoRoute(
      path: '/seller/orders/:id',
      builder: (context, state) {
        final orderId = state.pathParameters['id']!;
        return BlocProvider(
          create: (context) => OrderBloc(),
          child: OrderDetailPage(orderId: orderId),
        );
      },
    ),
  ]
  
);