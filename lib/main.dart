import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arivu_ai/app.dart';
import 'package:arivu_ai/features/model/models/model_catalog.dart';
import 'package:arivu_ai/tools/remainder_tools.dart';
import 'package:arivu_ai/utils/app_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle Flutter UI and framework-level errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[CRASH/UI] FlutterError: ${details.exceptionAsString()}');
  };

  // Replace default red/grey screen of death with a user-friendly recovery screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return GlobalAppErrorWidget(details: details);
  };

  // Handle uncaught asynchronous errors from Futures, Streams, and native bridges
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[CRASH/ASYNC] Uncaught async error: $error\n$stack');
    return true; // Mark as handled to prevent abrupt application abort
  };

  await NotificationService.instance.initialize();
  await ModelCatalog.loadFromAsset();

  runApp(
    const ProviderScope(
      child: ArivuAiApp(),
    ),
  );
}
