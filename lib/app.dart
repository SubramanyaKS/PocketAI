import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arivu_ai/features/model/presentation/model_setup_screen.dart';
import 'package:arivu_ai/provider/theme_provider.dart';
import 'package:arivu_ai/utils/theme.dart';

class ArivuAiApp extends ConsumerWidget {
  const ArivuAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arivu AI',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const ModelSetupScreen(),
    );
  }
}
