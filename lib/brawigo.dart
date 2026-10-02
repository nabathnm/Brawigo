import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/routes/router.dart';
import 'core/utils/constants/brawigo_colors.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'features/marketplace/presentation/bloc/marketplace_event.dart';

class BrawigoApp extends StatelessWidget {
  const BrawigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(supabaseClient: Supabase.instance.client),
        ),
        BlocProvider<MarketplaceBloc>(
          create: (context) => MarketplaceBloc()..add(LoadProducts()),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Brawigo',
        theme: ThemeData(
          primaryColor: BrawigoColors.blue400,
          scaffoldBackgroundColor: BrawigoColors.blue50,
          textTheme: GoogleFonts.plusJakartaSansTextTheme(Theme.of(context).textTheme),
          useMaterial3: true,
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
