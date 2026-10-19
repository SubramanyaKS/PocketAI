import 'package:flutter/material.dart';
import 'package:pocket_ai/features/model/presentation/model_setup_screen.dart';

class PocketAiApp extends StatelessWidget {
  const PocketAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pocket AI',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const ModelSetupScreen(),
    );
  }
}
