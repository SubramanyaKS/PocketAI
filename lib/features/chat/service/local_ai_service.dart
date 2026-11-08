import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:llamadart/llamadart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pocket_ai/features/chat/models/chat_message.dart';
import 'package:pocket_ai/features/chat/models/performance_metrics.dart';
import 'package:pocket_ai/features/chat/service/think_filter.dart';
import 'package:pocket_ai/features/model/models/model_catalog.dart';
import 'package:pocket_ai/features/model/models/model_spec.dart';

class LocalAiService extends ChangeNotifier {
  static LocalAiService? _currentInstance;

  /// Global or shared instance for cross-screen state access.
  static LocalAiService get instance => _currentInstance ??= LocalAiService();

  ModelSpec _activeModel = ModelCatalog.defaultModel;

  /// Currently active model specification.
  ModelSpec get activeModel => _activeModel;

  PerformanceMetrics? _performanceMetrics;
  PerformanceMetrics? get performanceMetrics => _performanceMetrics;

  final LlamaEngine _engine = LlamaEngine(LlamaBackend());
  final Dio _dio = Dio();

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  LocalAiService() {
    _currentInstance = this;
  }

  /// Returns the target local File for a given model specification.
  Future<File> getModelFile([ModelSpec? spec]) async {
    final modelSpec = spec ?? _activeModel;
    final appDir = await getApplicationSupportDirectory();
    final modelDir = Directory.fromUri(appDir.uri.resolve('models'));
    return File('${modelDir.path}/${modelSpec.fileName}');
  }

  /// Checks if a specific model specification is downloaded and has a valid GGUF header.
  Future<bool> isModelDownloaded(ModelSpec spec) async {
    final file = await getModelFile(spec);
    return await _hasGgufHeader(file);
  }

  /// Computes the total storage space in bytes occupied by all downloaded .gguf models.
  Future<int> getTotalModelsSizeBytes() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final modelDir = Directory.fromUri(appDir.uri.resolve('models'));
      if (!await modelDir.exists()) return 0;

      int total = 0;
      await for (final entity in modelDir.list()) {
        if (entity is File && entity.path.endsWith('.gguf')) {
          total += await entity.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Deletes a downloaded model file from storage to free up disk space.
  /// Throws [StateError] if attempting to delete the currently active model.
  Future<bool> deleteModel(ModelSpec spec) async {
    if (spec.id == _activeModel.id) {
      throw StateError(
        'Cannot delete the currently active model. Switch to another model first.',
      );
    }

    final file = await getModelFile(spec);
    if (await file.exists()) {
      await file.delete();
      debugPrint('[MODEL] Deleted model file: ${file.path}');
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<String> _prepareModel({
    ModelSpec? spec,
    void Function(int received, int total)? onDownloadProgress,
  }) async {
    final modelSpec = spec ?? _activeModel;
    final appDir = await getApplicationSupportDirectory();
    final modelDir = Directory.fromUri(appDir.uri.resolve('models'));

    await modelDir.create(recursive: true);

    final modelFile = File('${modelDir.path}/${modelSpec.fileName}');

    // Reuse an existing valid model.
    if (await _hasGgufHeader(modelFile)) {
      debugPrint('[PERF] Existing model found; skipping download: ${modelSpec.name}');
      return modelFile.path;
    }

    if (await modelFile.exists()) {
      await modelFile.delete();
    }

    final partialFile = File('${modelFile.path}.part');

    if (await partialFile.exists()) {
      await partialFile.delete();
    }

    final downloadTimer = Stopwatch()..start();

    try {
      await _dio.download(
        modelSpec.downloadUrl,
        partialFile.path,
        onReceiveProgress: onDownloadProgress,
      );

      // Capture size BEFORE renaming the partial file.
      if (!await partialFile.exists()) {
        throw StateError('The model download did not create a file.');
      }

      final downloadedBytes = await partialFile.length();

      debugPrint(
        '[PERF] Downloaded file size: '
        '${(downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
      );

      if (downloadedBytes == 0) {
        throw StateError('The downloaded model file is empty.');
      }

      if (!await _hasGgufHeader(partialFile)) {
        throw StateError('The downloaded file is not a valid GGUF model.');
      }

      // Cryptographic SHA-256 supply-chain verification (if checksum provided)
      if (modelSpec.sha256 != null) {
        if (!await _verifySha256(partialFile, modelSpec.sha256!)) {
          throw StateError(
            'Security alert: Model file failed SHA-256 integrity verification.',
          );
        }
      }

      await partialFile.rename(modelFile.path);
    } catch (_) {
      if (await partialFile.exists()) {
        await partialFile.delete();
      }
      rethrow;
    } finally {
      downloadTimer.stop();

      debugPrint(
        '[PERF] Download duration: '
        '${(downloadTimer.elapsedMilliseconds / 1000).toStringAsFixed(2)} s',
      );
    }

    return modelFile.path;
  }

  Future<bool> _verifySha256(File file, String expectedHash) async {
    if (!await file.exists()) return false;
    final verifyTimer = Stopwatch()..start();
    try {
      final digest = await sha256.bind(file.openRead()).first;
      verifyTimer.stop();
      debugPrint(
        '[SECURITY] Model SHA-256 verified in ${(verifyTimer.elapsedMilliseconds / 1000).toStringAsFixed(2)}s: $digest',
      );
      return digest.toString().toLowerCase() == expectedHash.toLowerCase();
    } catch (e) {
      debugPrint('[SECURITY] Error computing SHA-256 digest: $e');
      return false;
    }
  }

  Future<bool> _hasGgufHeader(File file) async {
    if (!await file.exists() || await file.length() < 4) {
      return false;
    }

    final header = await file.openRead(0, 4).first;
    return header.length == 4 &&
        header[0] == 0x47 &&
        header[1] == 0x47 &&
        header[2] == 0x55 &&
        header[3] == 0x46;
  }

  /// Loads the default or specified model into memory.
  Future<void> loadModel({
    ModelSpec? spec,
    void Function(int received, int total)? onDownloadProgress,
  }) async {
    final targetSpec = spec ?? _activeModel;
    if (_isLoaded && _activeModel.id == targetSpec.id) return;

    final totalTimer = Stopwatch()..start();
    final prepareTimer = Stopwatch()..start();
    Stopwatch? nativeLoadTimer;

    try {
      final modelPath = await _prepareModel(
        spec: targetSpec,
        onDownloadProgress: onDownloadProgress,
      );

      prepareTimer.stop();

      final modelFile = File(modelPath);
      final modelSizeMB = (await modelFile.length()) / (1024 * 1024);

      debugPrint(
        '[PERF] Model preparation: '
        '${(prepareTimer.elapsedMilliseconds / 1000).toStringAsFixed(2)} s',
      );
      debugPrint(
        '[PERF] Model file size: '
        '${modelSizeMB.toStringAsFixed(1)} MB',
      );

      nativeLoadTimer = Stopwatch()..start();

      try {
        await _engine.setModel(
          LlamaModel(ModelSource.path(modelPath)),
          params: const ModelParams(contextSize: 2048, numberOfThreads: 4),
        );
      } finally {
        nativeLoadTimer.stop();

        _performanceMetrics = PerformanceMetrics(
          modelLoadTimeMs: nativeLoadTimer.elapsedMilliseconds,
        );

        debugPrint(
          '[PERF] Native model load: '
          '${(nativeLoadTimer.elapsedMilliseconds / 1000).toStringAsFixed(2)} s',
        );
      }

      _activeModel = targetSpec;
      _isLoaded = true;
      notifyListeners();
      debugPrint('[PERF] Model "${targetSpec.name}" loaded successfully');
    } finally {
      if (prepareTimer.isRunning) {
        prepareTimer.stop();
      }

      totalTimer.stop();

      debugPrint(
        '[PERF] Preparation total: '
        '${(prepareTimer.elapsedMilliseconds / 1000).toStringAsFixed(2)} s',
      );

      debugPrint(
        '[PERF] Overall load operation: '
        '${(totalTimer.elapsedMilliseconds / 1000).toStringAsFixed(2)} s',
      );
    }
  }

  /// Hot-swaps the active model in memory with a newly chosen catalog model.
  Future<void> switchModel(
    ModelSpec spec, {
    void Function(int received, int total)? onDownloadProgress,
  }) async {
    await loadModel(
      spec: spec,
      onDownloadProgress: onDownloadProgress,
    );
  }

  static const String defaultChatSystemPrompt = '''
You are Pocket AI, an intelligent, privacy-focused offline AI assistant running locally on the user's mobile device.

Strict Operating Rules:
1. Relevance & Precision: Answer ONLY what the user explicitly asks. Do not provide unrequested background trivia or off-topic information.
2. Factuality & Hallucination Prevention: If you do not know a fact or if the question requires real-time information (e.g. current news, live weather, real-time sports, stock prices), state clearly and honestly: "I do not have real-time internet access to verify current data." Never invent facts, dates, external URLs, or phone numbers.
3. Clean Formatting: Use concise paragraphs, bullet points, or markdown code blocks where appropriate. Avoid filler phrases like "Sure, I can help with that!" or "As an AI...".
4. Hard Stop: Stop generating tokens immediately once your direct answer is complete. Never simulate follow-up user questions, fake conversation turns, or dialogue tags.
''';

  static const String defaultVoiceSystemPrompt = '''
You are Pocket Voice, an on-device voice assistant speaking directly through text-to-speech.

Strict Operating Rules:
1. Instant Direct Answer: Deliver your answer in 1 or 2 concise, natural, spoken English sentences. Never repeat or summarize the user's question.
2. Speech-Only Text: Never use markdown, asterisks, hashtags, bullet points, emojis, or code blocks. Use plain, easy-to-pronounce conversational words.
3. No Hallucinations: If a question is outside your knowledge or asks for real-time live data, simply state: "I don't have that information offline."
4. Immediate Termination: Provide only the spoken answer and stop immediately. Do not add filler greetings or sign-offs.
''';

  Stream<String> askStream(
    List<ChatMessage> conversation, {
    String? systemPrompt,
    int maxTokens = 256,
    double temperature = 0.3,
  }) async* {
    if (!_isLoaded) {
      throw StateError('Model has not been loaded');
    }

    final filter = ThinkFilter();

    final generationTimer = Stopwatch()..start();
    int? timeToFirstVisibleTextMs;
    var visibleCharacters = 0;
    final visibleOutput = StringBuffer();

    final effectiveSystemPrompt = systemPrompt ?? defaultChatSystemPrompt;

    final tokenStream = _engine.create(
      [
        LlamaChatMessage.fromText(
          role: LlamaChatRole.system,
          text: effectiveSystemPrompt.trim(),
        ),
        for (var i = 0; i < conversation.length; i++)
          LlamaChatMessage.fromText(
            role: LlamaChatRole.values.byName(conversation[i].role),
            text: i == conversation.length - 1 && conversation[i].role == 'user'
                ? '${conversation[i].content}\n/no_think'
                : conversation[i].content,
          ),
      ],
      params: GenerationParams(maxTokens: maxTokens, temp: temperature),
      enableThinking: false,
    );

    void recordVisibleText(String text) {
      if (text.isEmpty) return;

      // Record TTFT only once, after filtering hidden reasoning.
      timeToFirstVisibleTextMs ??= generationTimer.elapsedMilliseconds;

      visibleCharacters += text.length;
      visibleOutput.write(text);
    }

    try {
      await for (final chunk in tokenStream) {
        final cleaned = filter.process(chunk.text);

        if (cleaned.isNotEmpty) {
          recordVisibleText(cleaned);
          yield cleaned;
        }
      }

      // Include any visible text buffered by ThinkFilter.
      final remaining = filter.finish();

      if (remaining.isNotEmpty) {
        recordVisibleText(remaining);
        yield remaining;
      }
    } finally {
      generationTimer.stop();

      final totalMs = generationTimer.elapsedMilliseconds;
      final output = visibleOutput.toString().trim();

      final wordCount = output.isEmpty
          ? 0
          : output.split(RegExp(r'\s+')).length;

      final seconds = totalMs / 1000.0;

      debugPrint(
        '[PERF] TTFT: '
        '${timeToFirstVisibleTextMs == null ? "No visible output" : "$timeToFirstVisibleTextMs ms"}',
      );

      debugPrint('[PERF] Total generation time: ${seconds.toStringAsFixed(2)} s');
      debugPrint('[PERF] Visible characters: $visibleCharacters');
      debugPrint('[PERF] Visible words (approx): $wordCount');

      if (seconds > 0) {
        debugPrint(
          '[PERF] Visible output speed: '
          '${(wordCount / seconds).toStringAsFixed(2)} words/s',
        );

        debugPrint(
          '[PERF] Character throughput: '
          '${(visibleCharacters / seconds).toStringAsFixed(2)} chars/s',
        );
      }
    }
  }
}
