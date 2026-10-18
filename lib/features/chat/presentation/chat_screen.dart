import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pocket_ai/features/chat/service/local_ai_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> _messages = []; // Stores messages
  final TextEditingController _controller = TextEditingController();
  final LocalAiService _aiService = LocalAiService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _modelReady = false;
  bool _isLoadingModel = true;
  bool _isThinking = false;
  String _status = 'Checking for AI model...';
  String? _modelError;
  bool isListen=false;

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    if (_isLoadingModel &&
        _modelError == null &&
        _status != 'Checking for AI model...') {
      return;
    }

    setState(() {
      _isLoadingModel = true;
      _modelError = null;
      _status = 'Loading AI model...';
    });

    try {
      await _aiService.loadModel(
        onDownloadProgress: (received, total) {
          if (!mounted) return;

          setState(() {
            if (total > 0) {
              final percent = (received * 100 / total).clamp(0, 100).round();
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

      setState(() {
        _modelReady = true;
        _isLoadingModel = false;
        _status = 'AI is ready';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingModel = false;
        _status = 'Model unavailable';
        _modelError = _modelErrorMessage(e);
      });

      debugPrint('Model loading error: $e');
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

  Future<void> _sendMessage() async {
    final prompt = _controller.text.trim();

    // Validate before adding the user's message.
    if (prompt.isEmpty || !_modelReady || _isThinking) {
      return;
    }

    setState(() {
      _messages.add({'text': prompt, 'sender': 'me'});

      _isThinking = true;
    });

    _controller.clear();

    try {
      final answer = await _aiService.ask(prompt);

      if (!mounted) return;

      setState(() {
        _messages.add({'text': answer, 'sender': 'other'});
      });
    } catch (e, stackTrace) {
      debugPrint('Inference error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _messages.add({
          'text': 'Sorry, I could not generate a response. Please try again.',
          'sender': 'other',
        });
      });
    } finally {
      if (mounted) {
        setState(() {
          _isThinking = false;
        });
      }
    }
  }

  void _listen() async {
    if (!isListen) {
      bool available = await _speech.initialize(
        onStatus: (val) => log('onStatus: $val'),
        onError: (val) => log('onError: $val'),
      );
      print(available);
      if (available) {
        setState(() => isListen = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _controller.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => isListen = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _aiService.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE0E7FF),
                child: Icon(Icons.smart_toy_rounded, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pocket AI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172033),
                      ),
                    ),
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 12,
                        color: _modelReady ? Colors.green : Colors.orange,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            if (_modelError != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      color: Color(0xFF9A5B00),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _modelError!,
                        style: const TextStyle(
                          color: Color(0xFF684000),
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _isLoadingModel ? null : _initializeAI,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            if (_isLoadingModel && !_modelReady)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
            // Messages list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 20,
                ),
                itemCount: _messages.length + (_isThinking ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(width: 12),
                          Text('Pocket AI is thinking...'),
                        ],
                      ),
                    );
                  }
                  final message = _messages[index];
                  final isMe = message['sender'] == 'me';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      mainAxisAlignment: isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe) ...[
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0xFFE0E7FF),
                            child: Icon(
                              Icons.smart_toy_rounded,
                              size: 18,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFF4F46E5)
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(isMe ? 18 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              message['text'] ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: isMe
                                    ? Colors.white
                                    : const Color(0xFF20283A),
                              ),
                            ),
                          ),
                        ),
                        if (isMe) const SizedBox(width: 4),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Message input area
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5FA),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: const Color(0xFFE6E8EF)),
                      ),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Message Pocket AI...',
                          hintStyle: TextStyle(color: Color(0xFF9299A8)),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 13,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF4F46E5,
                          ).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: 'Send message',
                      icon: Icon(
                        isListen
                            ? Icons.mic
                            : Icons.mic_off,
                        color: Colors.white,
                      ),
                     onPressed: () { _listen();},
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF4F46E5,
                          ).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: 'Send message',
                      icon: Icon(
                        _isThinking
                            ? Icons.hourglass_top_rounded
                            : Icons.arrow_upward_rounded,
                        color: Colors.white,
                      ),
                      onPressed: (_modelReady && !_isThinking)
                          ? _sendMessage
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
