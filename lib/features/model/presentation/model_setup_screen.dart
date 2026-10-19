import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pocket_ai/features/chat/presentation/chat_screen.dart';
import 'package:pocket_ai/features/chat/service/local_ai_service.dart';

class ModelSetupScreen extends StatefulWidget {
  const ModelSetupScreen({super.key});

  @override
  State<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends State<ModelSetupScreen> {
  final LocalAiService _aiService = LocalAiService();

  bool _isLoading = false;
  String _status = 'Checking for AI model...';
  String? _error;
  double? _downloadProgress;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _downloadProgress = null;
      _status = 'Checking for AI model...';
    });

    try {
      await _aiService.loadModel(
        onDownloadProgress: (received, total) {
          if (!mounted) return;

          setState(() {
            if (total > 0) {
              final percent = (received * 100 / total).clamp(0, 100).round();
              _downloadProgress = percent / 100;
              _status = percent == 100
                  ? 'Loading AI model...'
                  : 'Downloading model: $percent%';
            } else {
              _status = 'Downloading AI model...';
            }
          });
        },
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(aiService: _aiService),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Model loading error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _status = 'Model unavailable';
        _error = _modelErrorMessage(error);
      });
    }
  }

  String _modelErrorMessage(Object error) {
    if (error is DioException &&
        (error.error is SocketException ||
            error.toString().contains('Failed host lookup'))) {
      return 'Could not reach Hugging Face. Check your internet connection '
          'or device DNS settings, then try again.';
    }

    if (error is DioException &&
        (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout)) {
      return 'The model download timed out. Check your connection and try again.';
    }

    return 'The model could not be downloaded or loaded. Check your connection '
        'and available storage, then try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 2,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: Color(0xFFE0E7FF),
                        child: Icon(
                          Icons.smart_toy_rounded,
                          size: 34,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Prepare Pocket AI',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _status,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF596174),
                        ),
                      ),
                      if (_isLoading) ...[
                        const SizedBox(height: 24),
                        LinearProgressIndicator(value: _downloadProgress),
                        const SizedBox(height: 12),
                        const Text(
                          'The model is stored on this device and reused '
                          'when you open the app again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF737B8C),
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF9A5B00),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _initializeModel,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
