import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'brawigo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final String apiUrl = dotenv.env['API_URL'] ?? '';
  final String apiKey = dotenv.env['API_KEY'] ?? '';

  if (apiUrl.isEmpty || apiKey.isEmpty) {
    debugPrint('Warning: API_URL or API_KEY is missing in the .env file.');
  } else {
    await Supabase.initialize(
      url: apiUrl,
      anonKey: apiKey,
    );
  }

  runApp(const BrawigoApp());
}
