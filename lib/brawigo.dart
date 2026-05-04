import 'package:flutter/material.dart';

class BrawigoApp extends StatelessWidget {
  const BrawigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brawigo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Welcome to Brawigo'),
        ),
      ),
    );
  }
}
