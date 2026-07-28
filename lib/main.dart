import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/routes/router.dart';
import './features/auth/presentation/blocs/auth_bloc.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'package:google_fonts/google_fonts.dart';
void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_API_URL']!;
  final supabaseAnonKey = dotenv.env['SUPABASE_API_KEY']!;

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(providers: [BlocProvider<AuthBloc>(create: (context) => AuthBloc(supabaseClient: Supabase.instance.client))],
     child: MaterialApp.router(
      title: 'Brawigo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: BrawigoColors.blue400,
        scaffoldBackgroundColor: BrawigoColors.blue50,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(Theme.of(context).textTheme),
      ),
      routerConfig: appRouter,
     ) );
  }
}
