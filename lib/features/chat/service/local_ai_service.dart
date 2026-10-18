import 'dart:io';

import 'package:dio/dio.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:path_provider/path_provider.dart';
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

  Future<String> ask(String prompt) async {
    if (!_isLoaded) {
      throw StateError('Model has not been loaded');
    }

    final response = await _controller
        .generateChat(
          messages: [
            ChatMessage(
              role: 'system',
              content:
                  'You are a helpful AI assistant named Pocket AI. '
                  'Always respond in clear, natural English. '
                  'Do not use Chinese characters unless the user '
                  'explicitly requests Chinese. '
                  'Reply naturally and concisely. '
                  'Do not show your reasoning or internal thoughts. '
                  'Use non-thinking mode. /no_think',
            ),
            ChatMessage(role: 'user', content: prompt),
          ],
          maxTokens: 50,
          temperature: 0.7,
        )
        .join();

    return response.replaceAll(RegExp(r'<think>\s*</think>'), '').trim();
  }

  Future<void> dispose() async {
    await _controller.dispose();
    _isLoaded = false;
  }
}
