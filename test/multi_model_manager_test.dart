// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ai/features/chat/service/local_ai_service.dart';
import 'package:pocket_ai/features/model/models/model_catalog.dart';
import 'package:pocket_ai/features/model/models/model_spec.dart';
import 'package:pocket_ai/features/settings/presentation/manage_models_screen.dart';
import 'package:pocket_ai/features/settings/presentation/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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
    tempDir = Directory.systemTemp.createTempSync('pocket_ai_test_models');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
    final catalogFile = File('assets/models/model_catalog.json');
    if (catalogFile.existsSync()) {
      ModelCatalog.loadFromJsonString(catalogFile.readAsStringSync());
    }
  });

  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ModelCatalog & ModelSpec Tests', () {
    test('ModelCatalog contains all verified mobile models', () {
      expect(ModelCatalog.allModels.length, 4);
      expect(ModelCatalog.defaultModel.id, 'qwen3-0.6b-q8_0');

      final ids = ModelCatalog.allModels.map((m) => m.id).toList();
      expect(ids, contains('qwen3-0.6b-q8_0'));
      expect(ids, contains('smollm2-360m'));
      expect(ids, contains('qwen2.5-0.5b'));
      expect(ids, contains('qwen2.5-1.5b-q4'));
    });

    test('ModelSpec sizeFormatted produces clean human-readable units', () {
      const specMb = ModelSpec(
        id: 'test-mb',
        name: 'Test MB',
        description: '',
        category: '',
        fileName: 'test.gguf',
        downloadUrl: '',
        sizeBytes: 639446688,
        recommendedRam: '',
      );
      expect(specMb.sizeFormatted, '610 MB');

      const specGb = ModelSpec(
        id: 'test-gb',
        name: 'Test GB',
        description: '',
        category: '',
        fileName: 'test.gguf',
        downloadUrl: '',
        sizeBytes: 1572864000,
        recommendedRam: '',
      );
      expect(specGb.sizeFormatted, '1.5 GB');
    });

    test('ModelCatalog.getById resolves model or falls back to default', () {
      final m1 = ModelCatalog.getById('smollm2-360m');
      expect(m1.name, contains('SmolLM2'));

      final mFallback = ModelCatalog.getById('non-existent-id');
      expect(mFallback.id, ModelCatalog.defaultModel.id);
    });

    test('ModelSpec json serialization and deserialization works correctly', () {
      final original = ModelCatalog.defaultModel;
      final jsonMap = original.toJson();
      final fromJson = ModelSpec.fromJson(jsonMap);

      expect(fromJson.id, original.id);
      expect(fromJson.name, original.name);
      expect(fromJson.sizeBytes, original.sizeBytes);
      expect(fromJson.sha256, original.sha256);
      expect(fromJson.fileName, original.fileName);
      expect(fromJson.category, original.category);
    });

    test('ModelCatalog loads successfully from JSON string', () {
      const jsonStr = '''
[
  {
    "id": "custom-model",
    "name": "Custom Model 1B",
    "description": "Custom parsed model from external JSON",
    "category": "Custom",
    "fileName": "custom-model.gguf",
    "downloadUrl": "https://example.com/model.gguf",
    "sizeBytes": 500000000,
    "sha256": null,
    "recommendedRam": "2GB+"
  }
]
''';
      final loaded = ModelCatalog.loadFromJsonString(jsonStr);
      expect(loaded.length, 1);
      expect(loaded.first.id, 'custom-model');
      expect(loaded.first.name, 'Custom Model 1B');

      // Reset back to defaults for subsequent tests
      ModelCatalog.loadFromJsonString('''
[
  {
    "id": "qwen3-0.6b-q8_0",
    "name": "Qwen3 0.6B Q8_0",
    "description": "Balanced default model with excellent conversational flow, tool use, and reasoning.",
    "category": "Balanced (Default)",
    "fileName": "Qwen3-0.6B-Q8_0.gguf",
    "downloadUrl": "https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf",
    "sizeBytes": 639446688,
    "sha256": "9465e63a22add5354d9bb4b99e90117043c7124007664907259bd16d043bb031",
    "recommendedRam": "2GB+ RAM"
  },
  {
    "id": "smollm2-360m",
    "name": "SmolLM2 360M Instruct",
    "description": "Ultra-compact model by Hugging Face optimized for sub-second voice replies and minimal battery use.",
    "category": "Ultra-Fast & Voice",
    "fileName": "smollm2-360m-instruct-q8_0.gguf",
    "downloadUrl": "https://huggingface.co/HuggingFaceTB/SmolLM2-360M-Instruct-GGUF/resolve/main/smollm2-360m-instruct-q8_0.gguf",
    "sizeBytes": 386270432,
    "sha256": null,
    "recommendedRam": "1.5GB+ RAM"
  },
  {
    "id": "qwen2.5-0.5b",
    "name": "Qwen2.5 0.5B Instruct",
    "description": "Fast lightweight assistant with strong multilingual and structured formatting capabilities.",
    "category": "Compact & Fast",
    "fileName": "qwen2.5-0.5b-instruct-q8_0.gguf",
    "downloadUrl": "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q8_0.gguf",
    "sizeBytes": 524822720,
    "sha256": null,
    "recommendedRam": "2GB+ RAM"
  },
  {
    "id": "qwen2.5-1.5b-q4",
    "name": "Qwen2.5 1.5B Instruct",
    "description": "High intelligence model with superior code generation, analysis, and complex reasoning.",
    "category": "High Intelligence & Code",
    "fileName": "qwen2.5-1.5b-instruct-q4_k_m.gguf",
    "downloadUrl": "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf",
    "sizeBytes": 1030000000,
    "sha256": null,
    "recommendedRam": "4GB+ RAM"
  }
]
''');
    });
  });

  group('LocalAiService Multi-Model Storage & Deletion Logic', () {
    late LocalAiService aiService;

    setUp(() {
      aiService = LocalAiService();
    });

    test('Active model starts as defaultModel', () {
      expect(aiService.activeModel.id, ModelCatalog.defaultModel.id);
    });

    test('Attempting to delete the currently active model throws StateError guard', () async {
      expect(
        () => aiService.deleteModel(aiService.activeModel),
        throwsA(isA<StateError>()),
      );
    });

    test('deleteModel returns false when target inactive file does not exist on disk', () async {
      final inactiveModel = ModelCatalog.getById('smollm2-360m');
      expect(inactiveModel.id, isNot(aiService.activeModel.id));

      final deleted = await aiService.deleteModel(inactiveModel);
      expect(deleted, isFalse);
    });

    test('deleteModel successfully removes inactive model file from disk', () async {
      final inactiveModel = ModelCatalog.getById('smollm2-360m');
      final file = await aiService.getModelFile(inactiveModel);
      await file.parent.create(recursive: true);
      await file.writeAsString('mock model data');
      expect(await file.exists(), isTrue);

      final deleted = await aiService.deleteModel(inactiveModel);
      expect(deleted, isTrue);
      expect(await file.exists(), isFalse);
    });
  });

  group('ManageModelsScreen & SettingsScreen Widget Tests', () {
    testWidgets('ManageModelsScreen renders catalog models and storage header',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final aiService = LocalAiService();

      await tester.pumpWidget(
        MaterialApp(
          home: ManageModelsScreen(aiService: aiService),
        ),
      );

      await tester.pumpAndSettle();

      // Top header
      expect(find.text('Manage AI Models'), findsOneWidget);
      expect(find.textContaining('Device Storage Used:'), findsOneWidget);

      // Model names
      expect(find.text('Qwen3 0.6B Q8_0'), findsOneWidget);
      expect(find.text('SmolLM2 360M Instruct'), findsOneWidget);
      expect(find.text('Qwen2.5 0.5B Instruct'), findsOneWidget);
      expect(find.text('Qwen2.5 1.5B Instruct'), findsOneWidget);

      // Active badge
      expect(find.text('Active in RAM'), findsOneWidget);
    });

    testWidgets('SettingsScreen displays AI MODEL & STORAGE section with Manage tile',
        (tester) async {
      final aiService = LocalAiService();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(aiService: aiService),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('AI MODEL & STORAGE'), findsOneWidget);
      expect(find.text('Manage & Delete Models'), findsOneWidget);
      expect(find.text('Qwen3 0.6B Q8_0'), findsOneWidget);
    });
  });
}
