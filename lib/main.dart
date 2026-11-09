import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arivu_ai/app.dart';
import 'package:arivu_ai/features/model/models/model_catalog.dart';
import 'package:arivu_ai/tools/remainder_tools.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  await ModelCatalog.loadFromAsset();

  runApp(
    const ProviderScope(
      child: ArivuAiApp(),
    ),
  );
}
