// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:arivu_ai/features/chat/service/local_ai_service.dart';
import 'package:arivu_ai/features/model/models/inference_config.dart';
import 'package:arivu_ai/features/settings/presentation/settings_screen.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String path;
  MockPathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('arivu_ai_test_inf');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
  });

  tearDownAll(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('InferenceConfig Unit Tests', () {
    test('Default values are initialized properly', () {
      const config = InferenceConfig();
      expect(config.numberOfThreads, equals(4));
      expect(config.contextSize, equals(2048));
      expect(config.temperature, equals(0.3));
      expect(config.maxTokens, equals(256));
    });

    test('copyWith properly overrides specific properties', () {
      const config = InferenceConfig();
      final updated = config.copyWith(
        numberOfThreads: 8,
        temperature: 0.7,
        contextSize: 4096,
        maxTokens: 512,
      );

      expect(updated.numberOfThreads, equals(8));
      expect(updated.contextSize, equals(4096));
      expect(updated.temperature, equals(0.7));
      expect(updated.maxTokens, equals(512));
    });

    test('toJson and fromJson serialize accurately', () {
      const original = InferenceConfig(
        numberOfThreads: 6,
        contextSize: 1024,
        temperature: 0.15,
        maxTokens: 128,
      );

      final json = original.toJson();
      final restored = InferenceConfig.fromJson(json);

      expect(restored, equals(original));
      expect(restored.numberOfThreads, equals(6));
      expect(restored.contextSize, equals(1024));
      expect(restored.temperature, equals(0.15));
      expect(restored.maxTokens, equals(128));
    });

    test('InferenceConfig.defaults equals default constructor', () {
      expect(InferenceConfig.defaults, equals(const InferenceConfig()));
    });
  });

  group('Inference Parameters UI Widget Tests', () {
    late LocalAiService aiService;

    setUp(() async {
      aiService = LocalAiService.instance;
      await aiService.updateInferenceConfig(InferenceConfig.defaults);
    });

    testWidgets('SettingsScreen renders all Inference Parameter controls and chips', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(aiService: aiService),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify section header and reset button
      expect(find.text('INFERENCE PARAMETERS'), findsOneWidget);
      expect(find.text('Reset Defaults'), findsOneWidget);

      // Verify CPU threads
      expect(find.text('CPU Generation Threads'), findsOneWidget);
      expect(find.text('4 Threads'), findsOneWidget);

      // Verify Sampling temperature
      expect(find.text('Sampling Temperature'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('0.30 • Balanced'), findsOneWidget);

      // Verify Context Window and Max Tokens
      expect(find.text('Context Window Size'), findsOneWidget);
      expect(find.text('2048 Tokens'), findsOneWidget);
      expect(find.text('1K (Eco)'), findsOneWidget);
      expect(find.text('2K (Default)'), findsOneWidget);
      expect(find.text('4K (Deep)'), findsOneWidget);

      // Verify Max Generation Tokens
      expect(find.text('Max Generation Tokens'), findsOneWidget);
      expect(find.text('256 Max Tokens'), findsOneWidget);
      expect(find.text('128'), findsOneWidget);
      expect(find.text('256'), findsOneWidget);
      expect(find.text('512'), findsOneWidget);
      expect(find.text('1024'), findsOneWidget);
    });

    testWidgets('Tapping thread chips updates active configuration', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(aiService: aiService),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially 4 threads
      expect(aiService.inferenceConfig.numberOfThreads, equals(4));
      expect(find.text('4 Threads'), findsOneWidget);

      // Tap '8' threads chip
      final chip8 = find.widgetWithText(ChoiceChip, '8');
      expect(chip8, findsOneWidget);
      await tester.tap(chip8);
      await tester.pumpAndSettle();

      // Check updated state on service and UI
      expect(aiService.inferenceConfig.numberOfThreads, equals(8));
      expect(find.text('8 Threads'), findsOneWidget);

      // Tap Reset Defaults
      final resetBtn = find.text('Reset Defaults');
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // Check state restored to 4
      expect(aiService.inferenceConfig.numberOfThreads, equals(4));
      expect(find.text('4 Threads'), findsOneWidget);
    });
  });
}
