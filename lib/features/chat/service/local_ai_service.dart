import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart' as llama;
import 'package:path_provider/path_provider.dart';
import 'package:pocket_ai/features/chat/models/chat_message.dart';
import 'package:pocket_ai/features/chat/models/performance_metrics.dart';
import 'package:pocket_ai/features/chat/service/think_filter.dart';
import 'package:pocket_ai/utils/constant.dart';

class LocalAiService {
  static const _modelFileName = modelFileName;
  static const _modelUrl = modelUrl;

  PerformanceMetrics? _performanceMetrics;

  PerformanceMetrics? get performanceMetrics => _performanceMetrics;

  final llama.LlamaController _controller = llama.LlamaController();
  final Dio _dio = Dio();

  bool _isLoaded = false;

  Future<String> _prepareModel({
    void Function(int received, int total)? onDownloadProgress,
  }) async {
    final appDir = await getApplicationSupportDirectory();
    final modelDir = Directory.fromUri(appDir.uri.resolve('models'));

    await modelDir.create(recursive: true);

    final modelFile = File('${modelDir.path}/$_modelFileName');

    // Reuse an existing valid model.
    if (await _hasGgufHeader(modelFile)) {
      debugPrint('[PERF] Existing model found; skipping download.');
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
        _modelUrl,
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

  Future<void> loadModel({
    void Function(int received, int total)? onDownloadProgress,
  }) async {
    if (_isLoaded) return;

    final totalTimer = Stopwatch()..start();
    final prepareTimer = Stopwatch()..start();
    Stopwatch? nativeLoadTimer;

    try {
      // Stage 1: Find or download and validate the GGUF file.
      final modelPath = await _prepareModel(
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

      // Stage 2: Native llama.cpp model initialization.
      nativeLoadTimer = Stopwatch()..start();

      try {
        await _controller.loadModel(
          modelPath: modelPath,
          threads: 4,
          contextSize: 2048,
        );
      } finally {
        nativeLoadTimer.stop();

        debugPrint(
          '[PERF] Native model load: '
          '${(nativeLoadTimer.elapsedMilliseconds / 1000).toStringAsFixed(2)} s',
        );
      }

      _isLoaded = true;
      debugPrint('[PERF] Model loaded successfully');
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

  // Future<void> loadModel({
  //   void Function(int received, int total)? onDownloadProgress,
  // }) async {

  //   if (_isLoaded) return;
  //   final stopwatch = Stopwatch()..start();

  //   final modelPath = await _prepareModel(
  //     onDownloadProgress: onDownloadProgress,
  //   );

  //   await _controller.loadModel(
  //     modelPath: modelPath,
  //     threads: 4,
  //     contextSize: 2048,
  //   );

  //     stopwatch.stop();

  //     _performanceMetrics = PerformanceMetrics(
  //       modelLoadTimeMs: stopwatch.elapsedMilliseconds,
  //     );
  //     print(
  //       'Model loaded in '
  //       '${_performanceMetrics!.modelLoadTimeSeconds} seconds',
  //     );

  //   _isLoaded = true;
  // }
  //
  Stream<String> askStream(List<ChatMessage> conversation) async* {
    if (!_isLoaded) {
      throw StateError('Model has not been loaded');
    }

    final filter = ThinkFilter();

    final generationTimer = Stopwatch()..start();
    int? timeToFirstVisibleTextMs;
    var visibleCharacters = 0;
    final visibleOutput = StringBuffer();

    final tokenStream = _controller.generateChat(
      messages: [
        llama.ChatMessage(
          role: 'system',
          content: '''
You are Pocket AI, a helpful offline assistant.

Rules:
- Answer directly and naturally in clear English.
- Provide only the final answer, not internal reasoning.
- Never output <think> or </think> tags.
- Never use placeholders such as [insert name].
- If you know the answer, provide it directly.
- If you do not know the answer, admit it honestly.
- Keep answers concise unless asked for details.
''',
        ),
        for (var i = 0; i < conversation.length; i++)
          llama.ChatMessage(
            role: conversation[i].role,
            content:
                i == conversation.length - 1 && conversation[i].role == 'user'
                ? '${conversation[i].content}\n/no_think'
                : conversation[i].content,
          ),
      ],
      maxTokens: 128,
      temperature: 0.3,
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
        final cleaned = filter.process(chunk);

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

      print(
        '[PERF] TTFT: '
        '${timeToFirstVisibleTextMs == null ? "No visible output" : "$timeToFirstVisibleTextMs ms"}',
      );

      print('[PERF] Total generation time: ${seconds.toStringAsFixed(2)} s');
      print('[PERF] Visible characters: $visibleCharacters');
      print('[PERF] Visible words (approx): $wordCount');

      if (seconds > 0) {
        print(
          '[PERF] Visible output speed: '
          '${(wordCount / seconds).toStringAsFixed(2)} words/s',
        );

        print(
          '[PERF] Character throughput: '
          '${(visibleCharacters / seconds).toStringAsFixed(2)} chars/s',
        );
      }
    }
  }
}
