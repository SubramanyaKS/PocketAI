import 'package:pocket_ai/tools/tool_registry.dart';
import 'package:pocket_ai/features/assistant/presentation/voice_utils.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:pocket_ai/features/chat/models/chat_message.dart';
import 'package:pocket_ai/features/chat/service/local_ai_service.dart';
import 'package:pocket_ai/features/settings/presentation/settings_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;



class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key, required this.aiService});

  final LocalAiService aiService;

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> _speechQueue = Future.value();
  String _pendingSpeechText = '';
  int _speechRunId = 0;
  bool _isContinuousMode = false;

  AssistantState _state = AssistantState.idle;
  String _userSpeech = '';
  String _aiResponse = '';
  String _statusMessage = 'Tap to start conversation';

  late final AnimationController _pulseController;
  late final AnimationController _waveController;
  late final AnimationController _orbitController;

  late final Animation<double> _pulseAnimation;

  final List<String> _quickSuggestions = [
    'What can you do offline?',
    'Check battery status',
    'Remind me to drink water in 10 minutes',
    'Turn on flashlight',
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);

    // Sequential audio queue: awaitSpeakCompletion blocks await _flutterTts.speak()
    // until the current utterance completes native playback.
    await _flutterTts.awaitSpeakCompletion(true);

    _flutterTts.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
      if (!mounted) return;
      setState(() {
        _state = AssistantState.idle;
        _statusMessage = 'Audio error. Tap to retry';
      });
    });
  }

  
  void _enqueueSpeech(String sentence, int runId) {
    final text = VoiceUtils.cleanSpokenText(sentence);
    // Ignore empty text or snippets without words
    if (text.trim().isEmpty || !RegExp(r'\w').hasMatch(text)) return;

    _speechQueue = _speechQueue.then((_) async {
      if (!mounted || runId != _speechRunId) return;

      if (_state != AssistantState.speaking) {
        setState(() {
          _state = AssistantState.speaking;
          _statusMessage = 'Speaking response...';
        });
      }

      await _flutterTts.speak(text);
    }).catchError((error) {
      debugPrint('TTS queue error: $error');
    });
  }

  List<String> _extractSentences() {
    final sentences = <String>[];
    final regex = RegExp(r'[.!?]["\u2019\u201D\)]*\s+');

    while (true) {
      final match = regex.firstMatch(_pendingSpeechText);
      if (match == null) break;

      final sentence = _pendingSpeechText.substring(0, match.end).trim();
      if (sentence.isNotEmpty) {
        sentences.add(sentence);
      }
      _pendingSpeechText = _pendingSpeechText.substring(match.end);
    }

    return sentences;
  }

  void _addSpeechToken(String token, int runId) {
    _pendingSpeechText += token;
    for (final sentence in _extractSentences()) {
      _enqueueSpeech(sentence, runId);
    }
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

  void _toggleContinuousMode() {
    setState(() {
      _isContinuousMode = !_isContinuousMode;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isContinuousMode
              ? 'Hands-free continuous mode enabled: Pocket Voice will auto-listen.'
              : 'Hands-free continuous mode disabled.',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      _statusMessage = _isContinuousMode
          ? 'Listening for your reply...'
          : 'Listening to your voice...';
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
        _statusMessage = _isContinuousMode
            ? 'Conversation paused. Tap to resume'
            : 'No speech detected. Tap to speak';
      });
      return;
    }

    final lower = _userSpeech.trim().toLowerCase();
    // In hands-free mode, verbal exit commands gracefully end the continuous loop
    if (_isContinuousMode &&
        (lower == 'stop' ||
            lower == 'goodbye' ||
            lower == 'bye' ||
            lower == 'exit' ||
            lower == 'quit')) {
      setState(() {
        _state = AssistantState.idle;
        _statusMessage = 'Conversation ended. Tap to speak';
        _userSpeech = '';
      });
      return;
    }

    _processWithAi(_userSpeech.trim());
  }

  // 
  
  Future<void> _processWithAi(String prompt) async {
    final runId = ++_speechRunId;

    _pendingSpeechText = '';
    _speechQueue = Future.value();

    setState(() {
      _state = AssistantState.thinking;
      _statusMessage = 'Pocket AI is thinking...';
      _aiResponse = '';
    });

    final toolResult = await ToolRegistry.dispatch(prompt);
    if (!mounted || runId != _speechRunId) return;

    if (toolResult.handled && toolResult.reply != null) {
      setState(() {
        _aiResponse = toolResult.reply!;
      });

      _enqueueSpeech(toolResult.reply!, runId);
      await _speechQueue;

      if (mounted && runId == _speechRunId) {
        if (_isContinuousMode) {
          setState(() {
            _state = AssistantState.idle;
            _statusMessage = 'Listening for reply...';
          });
          await Future.delayed(const Duration(milliseconds: 700));
          if (mounted && runId == _speechRunId && _isContinuousMode) {
            _startListening();
          }
        } else {
          setState(() {
            _state = AssistantState.idle;
            _statusMessage = 'Tap to speak again';
          });
        }
      }
      return;
    }

    final conversation = [
      ChatMessage(
        conversationId: 0,
        role: 'user',
        content: prompt,
        createdAt: DateTime.now(),
      ),
    ];

    final responseBuffer = StringBuffer();

    try {
      await for (final token in widget.aiService.askStream(
        conversation,
        systemPrompt: LocalAiService.defaultVoiceSystemPrompt,
        maxTokens: 120,
      )) {
        if (!mounted || runId != _speechRunId) return;

        responseBuffer.write(token);

        setState(() {
          _aiResponse = responseBuffer.toString();
        });

        // Send complete sentences to TTS immediately as tokens arrive
        _addSpeechToken(token, runId);
      }

      if (!mounted || runId != _speechRunId) return;

      // Speak any remaining incomplete sentence
      final remaining = _pendingSpeechText.trim();
      if (remaining.isNotEmpty) {
        _enqueueSpeech(remaining, runId);
      }
      _pendingSpeechText = '';

      // Wait for all queued sentences to complete playback
      await _speechQueue;

      if (!mounted || runId != _speechRunId) return;

      if (_isContinuousMode) {
        setState(() {
          _state = AssistantState.idle;
          _statusMessage = 'Listening for reply...';
          _aiResponse = VoiceUtils.cleanSpokenText(responseBuffer.toString());
        });

        // Breathing delay before opening the mic to prevent echo bleeding
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted && runId == _speechRunId && _isContinuousMode) {
          _startListening();
        }
      } else {
        setState(() {
          _state = AssistantState.idle;
          _statusMessage = 'Tap to speak again';
          _aiResponse = VoiceUtils.cleanSpokenText(responseBuffer.toString());
        });
      }
    } catch (e) {
      debugPrint('Voice AI error: $e');
      if (!mounted || runId != _speechRunId) return;

      setState(() {
        _state = AssistantState.idle;
        _statusMessage = 'Error generating response';
      });
    }
  }

  Future<void> _stopTts() async {
    _speechRunId++;
    _pendingSpeechText = '';

    await _flutterTts.stop();

    if (!mounted) return;

    setState(() {
      _state = AssistantState.idle;
      _statusMessage = 'Stopped. Tap to speak';
    });
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
        setState(() {
          _state = AssistantState.idle;
          _statusMessage = 'Cancelled';
        });
        break;
      case AssistantState.speaking:
        _stopTts();
        if (_isContinuousMode) {
          // Tap-to-interrupt / barge-in: immediately open mic for user speech
          _startListening();
        }
        break;
    }
  }

  void _useSuggestion(String text) {
    if (_state != AssistantState.idle) return;
    setState(() {
      _userSpeech = text;
    });
    _processWithAi(text);
  }


  @override
  void dispose() {
    _speechRunId++;
    _pulseController.dispose();
    _waveController.dispose();
    _orbitController.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = VoiceUtils.getGradients(_state, isDark);
    final primaryColor = VoiceUtils.getPrimaryColor(_state);
    final isPulsing =
        _state == AssistantState.listening || _state == AssistantState.speaking;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.3),
                      primaryColor.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF6366F1),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pocket Voice',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '100% Offline AI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: _isContinuousMode
                  ? 'Hands-Free Loop: ON'
                  : 'Hands-Free Loop: OFF',
              icon: Icon(
                _isContinuousMode
                    ? Icons.all_inclusive_rounded
                    : Icons.all_inclusive_outlined,
                color: _isContinuousMode
                    ? const Color(0xFF10B981)
                    : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
                size: 22,
              ),
              onPressed: _toggleContinuousMode,
            ),
            if (_userSpeech.isNotEmpty || _aiResponse.isNotEmpty)
              IconButton(
                tooltip: 'Clear screen',
                icon: Icon(
                  Icons.refresh_rounded,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  size: 22,
                ),
                onPressed: () {
                  _stopTts();
                  setState(() {
                    _userSpeech = '';
                    _aiResponse = '';
                    _state = AssistantState.idle;
                    _statusMessage = 'Tap to start conversation';
                  });
                },
              ),
            IconButton(
              tooltip: 'Settings',
              icon: Icon(
                Icons.settings_outlined,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(aiService: widget.aiService),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),

            // Hands-Free Interactive Chip
            GestureDetector(
              onTap: _toggleContinuousMode,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _isContinuousMode
                      ? const Color(0xFF10B981)
                          .withValues(alpha: isDark ? 0.20 : 0.12)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isContinuousMode
                        ? const Color(0xFF10B981).withValues(alpha: 0.5)
                        : (isDark ? Colors.white12 : Colors.black12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.all_inclusive_rounded,
                      size: 13,
                      color: _isContinuousMode
                          ? const Color(0xFF10B981)
                          : (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isContinuousMode
                          ? 'Hands-Free Loop: ON'
                          : 'Hands-Free Loop: OFF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: _isContinuousMode
                            ? const Color(0xFF10B981)
                            : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Animated Status Pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.10),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_state == AssistantState.thinking)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor,
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Conversation display card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF131B2E).withValues(alpha: 0.85)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.4 : 0.04,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_userSpeech.isEmpty && _aiResponse.isEmpty) ...[
                            Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFEEF2FF),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE0E7FF),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.graphic_eq_rounded,
                                      size: 36,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'How can I help you today?',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Speak naturally. Answers are generated on-device with zero internet.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: _quickSuggestions
                                        .map((suggestion) => ActionChip(
                                              label: Text(
                                                suggestion,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? const Color(0xFFCBD5E1)
                                                      : const Color(0xFF334155),
                                                ),
                                              ),
                                              backgroundColor: isDark
                                                  ? const Color(0xFF1E293B)
                                                  : const Color(0xFFF1F5F9),
                                              side: BorderSide(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.1)
                                                    : const Color(0xFFE2E8F0),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              onPressed: () =>
                                                  _useSuggestion(suggestion),
                                            ))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ] else ...[
                            if (_userSpeech.isNotEmpty) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB)
                                          .withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: Color(0xFF60A5FA),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'You',
                                          style: TextStyle(
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _userSpeech,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Divider(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFE2E8F0),
                                height: 1,
                              ),
                              const SizedBox(height: 20),
                            ],

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    color: primaryColor,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pocket AI',
                                        style: TextStyle(
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (_state == AssistantState.thinking &&
                                          _aiResponse.isEmpty) ...[
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: primaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Generating answer...',
                                              style: TextStyle(
                                                color: isDark
                                                    ? const Color(0xFF94A3B8)
                                                    : const Color(0xFF64748B),
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        Text(
                                          _aiResponse.isEmpty
                                              ? 'Processing your request...'
                                              : _aiResponse,
                                          style: TextStyle(
                                            color: isDark
                                                ? const Color(0xFFE2E8F0)
                                                : const Color(0xFF1E293B),
                                            fontSize: 16,
                                            height: 1.5,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Live Audio Wave Animation Bar
            SizedBox(
              height: 36,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(24, (index) {
                      final waveOffset = index * 0.26;
                      final rawSin = math.sin(
                          (_waveController.value * 2 * math.pi) + waveOffset);
                      final normalized = (rawSin + 1) / 2;

                      final height = isPulsing
                          ? 6 + (normalized * 26)
                          : (_state == AssistantState.thinking
                              ? 4 + (math.sin(index * 0.5) * 6).abs()
                              : 4.0);

                      return Container(
                        width: 3.5,
                        height: height,
                        margin: const EdgeInsets.symmetric(horizontal: 2.2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isPulsing
                              ? primaryColor.withValues(
                                  alpha: 0.4 + (normalized * 0.6))
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : const Color(0xFFCBD5E1)),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Glowing Animated Voice Orb Button
            Center(
              child: GestureDetector(
                onTap: _onMainButtonPressed,
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _orbitController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _orbitController.value * 2 * math.pi,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primaryColor.withValues(
                                      alpha: isPulsing ? 0.35 : 0.15),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          final scale =
                              isPulsing ? _pulseAnimation.value : 1.0;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(
                                      alpha: isPulsing ? 0.55 : 0.25,
                                    ),
                                    blurRadius: isPulsing ? 32 : 18,
                                    spreadRadius: isPulsing ? 8 : 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            VoiceUtils.getButtonIcon(_state),
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              VoiceUtils.getSubtitleTip(_state),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : const Color(0xFF64748B),
                letterSpacing: 0.2,
              ),
            ),

            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
