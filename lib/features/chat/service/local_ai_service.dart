import 'dart:io';

import 'package:dio/dio.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pocket_ai/features/chat/service/think_filter.dart';
import 'package:pocket_ai/utils/constant.dart';

class LocalAiService {
  static const _modelFileName = modelFileName;
  static const _modelUrl = modelUrl;

  final LlamaController _controller = LlamaController();
  final Dio _dio = Dio();

  bool _isLoaded = false;

  Future<String> _prepareModel({
    void Function(int received, int total)? onDownloadProgress,
  }) async {
    final appDir = await getApplicationSupportDirectory();
    final modelDir = Directory.fromUri(appDir.uri.resolve('models'));

    await modelDir.create(recursive: true);
    final modelFile = File('${modelDir.path}/$_modelFileName');

    if (await _hasGgufHeader(modelFile)) {
      return modelFile.path;
    }

    if (await modelFile.exists()) {
      await modelFile.delete();
    }

    final partialFile = File('${modelFile.path}.part');
    if (await partialFile.exists()) {
      await partialFile.delete();
    }

    try {
      await _dio.download(
        _modelUrl,
        partialFile.path,
        onReceiveProgress: onDownloadProgress,
      );

      if (!await partialFile.exists() || await partialFile.length() == 0) {
        throw StateError('The model download completed without a model file.');
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

    final modelPath = await _prepareModel(
      onDownloadProgress: onDownloadProgress,
    );

    await _controller.loadModel(
      modelPath: modelPath,
      threads: 4,
      contextSize: 2048,
    );

    _isLoaded = true;
  }

  
Stream<String> askStream(String prompt) async* {
  if (!_isLoaded) {
    throw StateError('Model has not been loaded');
  }

  final filter = ThinkFilter();

  final tokenStream = _controller.generateChat(
    messages: [
      ChatMessage(
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
      ChatMessage(
        role: 'user',
        content: prompt,
      ),
    ],
    maxTokens: 256,
    temperature: 0.3,
  );

  await for (final chunk in tokenStream) {
    final cleaned = filter.process(chunk);

    if (cleaned.isNotEmpty) {
      yield cleaned;
    }
  }

  final remaining = filter.finish();

  if (remaining.isNotEmpty) {
    yield remaining;
  }
}
}