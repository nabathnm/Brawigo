import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:brawigo/core/routes/router.dart';
import 'package:brawigo/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:brawigo/features/marketplace/presentation/bloc/marketplace_event.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('id_ID', null);

  final supabaseUrl = dotenv.env['SUPABASE_API_URL']!;
  final supabaseAnonKey = dotenv.env['SUPABASE_API_KEY']!;

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) =>
              AuthBloc(supabaseClient: Supabase.instance.client),
        ),
        BlocProvider<MarketplaceBloc>(
          create: (context) => MarketplaceBloc()..add(LoadProducts()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Brawigo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          primaryColor: BrawigoColors.blue600,
          scaffoldBackgroundColor: BrawigoColors.blue50,
          textTheme: GoogleFonts.plusJakartaSansTextTheme(
            Theme.of(context).textTheme,
          ),
          canvasColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(
            seedColor: BrawigoColors.blue600,
            primary: BrawigoColors.blue600,
            secondary: BrawigoColors.blue400,
            surface: Colors.white,
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: BrawigoColors.blue600,
          ),
          radioTheme: RadioThemeData(
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return BrawigoColors.blue600;
              }
              return const Color(0xFF64748B);
            }),
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return BrawigoColors.blue600;
              }
              return Colors.transparent;
            }),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: BrawigoColors.blue600,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
