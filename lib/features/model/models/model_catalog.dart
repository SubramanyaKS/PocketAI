import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'model_spec.dart';

/// Catalog of verified GGUF models loaded dynamically from
/// `assets/models/model_catalog.json`.
class ModelCatalog {
  ModelCatalog._();

  /// Asset path to the bundled JSON catalog configuration.
  static const String assetPath = 'assets/models/model_catalog.json';

  static List<ModelSpec> _models = [];

  /// All catalog models currently loaded from assets/models/model_catalog.json.
  static List<ModelSpec> get allModels => List.unmodifiable(_models);

  /// Default model (first model in the catalog, or marked as default).
  static ModelSpec get defaultModel {
    if (_models.isNotEmpty) {
      return _models.firstWhere(
        (m) => m.category.toLowerCase().contains('default'),
        orElse: () => _models.first,
      );
    }
    // Fallback if accessed before async load finishes
    return const ModelSpec(
      id: 'qwen3-0.6b-q8_0',
      name: 'Qwen3 0.6B Q8_0',
      description:
          'Balanced default model with excellent conversational flow, tool use, and reasoning.',
      category: 'Balanced (Default)',
      fileName: 'Qwen3-0.6B-Q8_0.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf',
      sizeBytes: 639446688,
      sha256: '9465e63a22add5354d9bb4b99e90117043c7124007664907259bd16d043bb031',
      recommendedRam: '2GB+ RAM',
    );
  }

  /// Asynchronously loads and parses model specifications from `assets/models/model_catalog.json`.
  static Future<List<ModelSpec>> loadFromAsset([String path = assetPath]) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final loaded = jsonList
          .map((item) => ModelSpec.fromJson(item as Map<String, dynamic>))
          .toList();
      if (loaded.isNotEmpty) {
        _models = loaded;
      }
    } catch (e) {
      debugPrint('[CATALOG] Error loading catalog from asset ($path): $e');
    }
    return allModels;
  }

  /// Parses and loads model specifications directly from a JSON string.
  static List<ModelSpec> loadFromJsonString(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    _models = jsonList
        .map((item) => ModelSpec.fromJson(item as Map<String, dynamic>))
        .toList();
    return allModels;
  }

  /// Finds a model by ID or returns defaultModel if not found.
  static ModelSpec getById(String id) {
    return _models.firstWhere(
      (m) => m.id == id,
      orElse: () => defaultModel,
    );
  }
}
