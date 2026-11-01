import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:pocket_ai/features/chat/models/chat_message.dart';
import 'package:pocket_ai/features/chat/service/local_ai_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum AssistantState {
  idle,
  listening,
  thinking,
  speaking,
}

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key, required this.aiService});

  final LocalAiService aiService;

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  AssistantState _state = AssistantState.idle;
  String _userSpeech = '';
  String _aiResponse = '';
  String _statusMessage = 'Tap the microphone to speak';

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);

    _flutterTts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _state = AssistantState.idle;
        _statusMessage = 'Tap to speak again';
      });
    });

    _flutterTts.setErrorHandler((msg) {
      if (!mounted) return;
      setState(() {
        _state = AssistantState.idle;
        _statusMessage = 'Audio playback error';
      });
    });
  }

  Future<void> _initSpeech() async {
    try {
      await _speech.initialize(
        onError: (val) {
          if (!mounted) return;
          if (_state == AssistantState.listening) {
            setState(() {
              _state = AssistantState.idle;
              _statusMessage = 'Mic error: ${val.errorMsg}';
            });
          }
        },
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            if (_state == AssistantState.listening) {
              _onSpeechDone();
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Speech init failed: $e');
    }
  }

  Future<void> _startListening() async {
    await _stopTts();

    final available = await _speech.initialize();
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is unavailable.')),
      );
      return;
    }

    setState(() {
      _state = AssistantState.listening;
      _userSpeech = '';
      _aiResponse = '';
      _statusMessage = 'Listening...';
    });

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
      ),
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _userSpeech = result.recognizedWords;
        });

        if (result.finalResult && _userSpeech.trim().isNotEmpty) {
          _speech.stop();
          _onSpeechDone();
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    _onSpeechDone();
  }

  void _onSpeechDone() {
    if (_state != AssistantState.listening) return;

    if (_userSpeech.trim().isEmpty) {
      setState(() {
        _state = AssistantState.idle;
        _statusMessage = 'No speech detected. Tap to retry.';
      });
      return;
    }

    _processWithAi(_userSpeech.trim());
  }

  Future<void> _processWithAi(String prompt) async {
    setState(() {
      _state = AssistantState.thinking;
      _statusMessage = 'Thinking...';
      _aiResponse = '';
    });

    final conversation = [
      ChatMessage(
        conversationId: 0,
        role: 'user',
        content:
            '$prompt\n(Instruction: Keep your response short, conversational, and direct in 1-2 spoken sentences. Avoid markdown, asterisks, bullet points, or lists.)',
        createdAt: DateTime.now(),
      ),
    ];

    final buffer = StringBuffer();
    bool hasStartedSpeaking = false;

    try {
      await for (final token in widget.aiService.askStream(conversation)) {
        if (!mounted || _state == AssistantState.idle) break;

        buffer.write(token);

        setState(() {
          _aiResponse = buffer.toString();
        });

        // Trigger TTS early once we have a completed first sentence
        if (!hasStartedSpeaking && _containsSentenceEnding(buffer.toString())) {
          hasStartedSpeaking = true;
          setState(() {
            _state = AssistantState.speaking;
            _statusMessage = 'Speaking...';
          });
        }
      }

      if (!mounted) return;

      final finalText = _cleanSpokenText(buffer.toString());
      if (finalText.isEmpty) {
        setState(() {
          _state = AssistantState.idle;
          _statusMessage = 'No response generated. Tap to try again.';
        });
        return;
      }

      setState(() {
        _state = AssistantState.speaking;
        _statusMessage = 'Speaking...';
        _aiResponse = finalText;
      });

      await _flutterTts.speak(finalText);
    } catch (e) {
      debugPrint('AI Inference error in voice assistant: $e');
      if (!mounted) return;
      setState(() {
        _state = AssistantState.idle;
        _statusMessage = 'Error generating response: $e';
      });
    }
  }

  bool _containsSentenceEnding(String text) {
    return text.contains('.') || text.contains('?') || text.contains('!');
  }

  String _cleanSpokenText(String input) {
    return input
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'#+'), '')
        .replaceAll(RegExp(r'`+'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .trim();
  }

  Future<void> _stopTts() async {
    await _flutterTts.stop();
    if (mounted && _state == AssistantState.speaking) {
      setState(() {
        _state = AssistantState.idle;
        _statusMessage = 'Stopped. Tap to speak';
      });
    }
  }

  void _onMainButtonPressed() {
    switch (_state) {
      case AssistantState.idle:
        _startListening();
        break;
      case AssistantState.listening:
        _stopListening();
        break;
      case AssistantState.thinking:
        // Cancel / reset
        setState(() {
          _state = AssistantState.idle;
          _statusMessage = 'Cancelled';
        });
        break;
      case AssistantState.speaking:
        _stopTts();
        break;
    }
  }

  Color _getPrimaryColor() {
    switch (_state) {
      case AssistantState.idle:
        return const Color(0xFF4F46E5);
      case AssistantState.listening:
        return const Color(0xFFEF4444);
      case AssistantState.thinking:
        return const Color(0xFFF59E0B);
      case AssistantState.speaking:
        return const Color(0xFF10B981);
    }
  }

  IconData _getButtonIcon() {
    switch (_state) {
      case AssistantState.idle:
        return Icons.mic_rounded;
      case AssistantState.listening:
        return Icons.stop_rounded;
      case AssistantState.thinking:
        return Icons.hourglass_top_rounded;
      case AssistantState.speaking:
        return Icons.volume_up_rounded;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getPrimaryColor();

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.graphic_eq_rounded, color: activeColor, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice Assistant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Offline Voice Mode',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Status text header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: activeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Conversation display container
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_userSpeech.isNotEmpty) ...[
                          const Row(
                            children: [
                              Icon(Icons.person_outline, size: 16, color: Color(0xFF64748B)),
                              SizedBox(width: 6),
                              Text(
                                'You said:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _userSpeech,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                        ],

                        const Row(
                          children: [
                            Icon(Icons.smart_toy_outlined, size: 16, color: Color(0xFF64748B)),
                            SizedBox(width: 6),
                            Text(
                              'Pocket AI:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (_state == AssistantState.thinking && _aiResponse.isEmpty) ...[
                          Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: activeColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Generating spoken response...',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            _aiResponse.isEmpty
                                ? (_userSpeech.isEmpty
                                    ? 'Tap the microphone below and speak naturally. Everything is processed offline on your device.'
                                    : 'Processing...')
                                : _aiResponse,
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.5,
                              color: _aiResponse.isEmpty
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Interactive Animated Action Button
              GestureDetector(
                onTap: _onMainButtonPressed,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    final isPulsing = _state == AssistantState.listening ||
                        _state == AssistantState.speaking;
                    final scale = isPulsing ? _pulseAnimation.value : 1.0;

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: activeColor,
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withValues(
                                alpha: isPulsing ? 0.45 : 0.25,
                              ),
                              blurRadius: isPulsing ? 28 : 16,
                              spreadRadius: isPulsing ? 6 : 2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getButtonIcon(),
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              Text(
                _state == AssistantState.listening
                    ? 'Tap to stop & send'
                    : (_state == AssistantState.speaking
                        ? 'Tap to stop audio'
                        : (_state == AssistantState.thinking
                            ? 'Tap to cancel'
                            : 'Tap to speak')),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
