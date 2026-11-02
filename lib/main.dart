import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_ai/app.dart';
import 'package:pocket_ai/tools/remainder_tools.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: PocketAiApp(),
    ),
  );
}
