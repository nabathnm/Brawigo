import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/complete_profile_page.dart';
import '../../features/marketplace/presentation/pages/main_screen.dart';
import '../../features/auth/presentation/pages/set_photo_page.dart';
import '../../features/auth/presentation/pages/onboarding_success_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation : '/splash',
  debugLogDiagnostics: true,

  routes: [
    GoRoute(path: '/splash',builder: (context,state) => const SplashPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
    GoRoute(path: '/otp', builder: (context, state) {
      final email = state.extra as String ?? '';
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
    GoRoute(path: '/home', builder: (context, state) => const MainScreen()),
  ]
  
);