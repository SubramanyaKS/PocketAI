import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:pocket_ai/features/chat/models/chat_message.dart';
import 'package:pocket_ai/features/chat/service/chat_database.dart';
import 'package:pocket_ai/features/chat/service/local_ai_service.dart';
import 'package:pocket_ai/features/chat/widgets/chat_empty_widget.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.aiService});

  final LocalAiService aiService;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final ChatDatabase _chatDatabase = ChatDatabase.instance;
  final TextEditingController _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  List<Map<String, dynamic>> _conversations = [];
  int? _currentConversationId;

  final bool _modelReady = true;
  bool _isThinking = false;
  bool _hasResponseStarted = false;
  bool _isHistoryReady = false;
  final String _status = 'AI is ready';
  String? _historyError;
  bool isListen = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final conversations = await _chatDatabase.getConversations();
      final mostRecent = conversations.isEmpty ? null : conversations.first;
      final messages = mostRecent == null
          ? <ChatMessage>[]
          : await _chatDatabase.getMessages(mostRecent['id'] as int);

      if (!mounted) return;

      setState(() {
        _conversations = conversations;
        _currentConversationId = mostRecent?['id'] as int?;
        _messages
          ..clear()
          ..addAll(messages);
        _historyError = null;
        _isHistoryReady = true;
      });
    } catch (error, stackTrace) {
      debugPrint('Chat history loading error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _historyError = 'Chat history could not be loaded. Please try again.';
        _isHistoryReady = false;
      });
    }
  }

  Future<void> _refreshConversations() async {
    final conversations = await _chatDatabase.getConversations();
    if (!mounted) return;

    setState(() {
      _conversations = conversations;
    });
  }

  Future<void> _selectConversation(int id) async {
    if (_isThinking) return;
    Navigator.of(context).pop();

    try {
      final messages = await _chatDatabase.getMessages(id);
      if (!mounted) return;

      setState(() {
        _currentConversationId = id;
        _messages
          ..clear()
          ..addAll(messages);
        _historyError = null;
      });
    } catch (error, stackTrace) {
      debugPrint('Conversation loading error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showHistoryError('This conversation could not be loaded.');
    }
  }

  void _startNewChat({bool closeDrawer = false}) {
    if (_isThinking) return;

    if (closeDrawer) Navigator.of(context).pop();
    setState(() {
      _currentConversationId = null;
      _messages.clear();
    });
  }

  Future<void> _deleteConversation(int id) async {
    final conversation = _conversations.firstWhere((item) => item['id'] == id);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: Text(
          '"${conversation['title']}" will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    try {
      await _chatDatabase.deleteConversation(id);
      final conversations = await _chatDatabase.getConversations();
      if (!mounted) return;

      if (_currentConversationId == id) {
        final mostRecent = conversations.isEmpty ? null : conversations.first;
        final messages = mostRecent == null
            ? <ChatMessage>[]
            : await _chatDatabase.getMessages(mostRecent['id'] as int);
        if (!mounted) return;

        setState(() {
          _currentConversationId = mostRecent?['id'] as int?;
          _messages
            ..clear()
            ..addAll(messages);
          _conversations = conversations;
        });
      } else {
        setState(() {
          _conversations = conversations;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Conversation deletion error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showHistoryError('This conversation could not be deleted.');
    }
  }

  void _showHistoryError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _conversationTitle(String prompt) {
    final characters = prompt.runes.toList();
    if (characters.length <= 48) return prompt;
    return '${String.fromCharCodes(characters.take(48))}...';
  }

  List<ChatMessage> _buildContextMessages(
    String prompt,
    ChatMessage currentMessage,
  ) {
    const maxInputCharacters = 3000;
    const maxHistoryMessages = 6;
    var remainingHistoryCharacters = maxInputCharacters - prompt.runes.length;
    final history = <ChatMessage>[];
    final previousMessages = _messages.take(_messages.length - 1).toList();

    for (final message in previousMessages.reversed) {
      if (history.length == maxHistoryMessages ||
          remainingHistoryCharacters <= 0) {
        break;
      }
      if ((message.role != 'user' && message.role != 'assistant') ||
          message.content.trim().isEmpty) {
        continue;
      }

      final messageCharacters = message.content.runes.length;
      if (messageCharacters > remainingHistoryCharacters) break;

      history.add(message);
      remainingHistoryCharacters -= messageCharacters;
    }

    return [...history.reversed, currentMessage];
  }

  Future<void> _sendMessage() async {
    final prompt = _controller.text.trim();

    if (prompt.isEmpty || !_modelReady || !_isHistoryReady || _isThinking) {
      return;
    }

    setState(() {
      _isThinking = true;
      _hasResponseStarted = false;
    });

    final createdAt = DateTime.now();
    final createdConversation = _currentConversationId == null;
    int? conversationId = _currentConversationId;
    late final ChatMessage userMessage;

    try {
      conversationId ??= await _chatDatabase.createConversation(
        _conversationTitle(prompt),
      );

      userMessage = ChatMessage(
        conversationId: conversationId,
        role: 'user',
        content: prompt,
        createdAt: createdAt,
      );

      await _chatDatabase.saveMessage(userMessage);
    } catch (error, stackTrace) {
      debugPrint('User message persistence error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (createdConversation && conversationId != null) {
        try {
          await _chatDatabase.deleteConversation(conversationId);
        } catch (cleanupError, cleanupStackTrace) {
          debugPrint('Empty conversation cleanup error: $cleanupError');
          debugPrintStack(stackTrace: cleanupStackTrace);
        }
      }

      if (!mounted) return;

      setState(() => _isThinking = false);
      _showHistoryError('Your message could not be saved. Please try again.');
      return;
    }

    final savedConversationId = conversationId;

    if (!mounted) return;

    setState(() {
      _currentConversationId = savedConversationId;
      _messages.add(userMessage);
    });

    _controller.clear();

    try {
      await _refreshConversations();
    } catch (error, stackTrace) {
      debugPrint('Conversation list refresh error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showHistoryError('Chat history could not be refreshed.');
    }

    if (!mounted) return;

    final assistantCreatedAt = DateTime.now();
    final assistantMessageIndex = _messages.length;
    final responseBuffer = StringBuffer();
    final contextMessages = _buildContextMessages(prompt, userMessage);

    try {
      // Receive and display each chunk as it arrives.
      await for (final chunk in widget.aiService.askStream(contextMessages)) {
        responseBuffer.write(chunk);

        if (responseBuffer.toString().trim().isEmpty) continue;
        if (!mounted) return;

        setState(() {
          final message = ChatMessage(
            conversationId: savedConversationId,
            role: 'assistant',
            content: responseBuffer.toString(),
            createdAt: assistantCreatedAt,
          );
          if (_messages.length == assistantMessageIndex) {
            _messages.add(message);
          } else {
            _messages[assistantMessageIndex] = message;
          }
          _hasResponseStarted = true;
        });
      }

      if (responseBuffer.toString().trim().isEmpty) {
        responseBuffer.clear();
        responseBuffer.write(
          'Sorry, I could not generate a response. Please try again.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Inference error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (responseBuffer.toString().trim().isEmpty) {
        responseBuffer.clear();
        responseBuffer.write(
          'Sorry, I could not generate a response. Please try again.',
        );
      }
    }

    if (!mounted) return;

    // Save the final assistant response to the database.
    final assistantMessage = ChatMessage(
      conversationId: savedConversationId,
      role: 'assistant',
      content: responseBuffer.toString(),
      createdAt: assistantCreatedAt,
    );

    try {
      await _chatDatabase.saveMessage(assistantMessage);
    } catch (error, stackTrace) {
      debugPrint('Assistant message persistence error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _showHistoryError('The response could not be saved to chat history.');
    }

    if (!mounted) return;

    setState(() {
      if (_messages.length == assistantMessageIndex) {
        _messages.add(assistantMessage);
      } else {
        _messages[assistantMessageIndex] = assistantMessage;
      }
      _isThinking = false;
      _hasResponseStarted = false;
    });

    try {
      await _refreshConversations();
    } catch (error, stackTrace) {
      debugPrint('Conversation list refresh error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _showHistoryError('Chat history could not be refreshed.');
    }
  }

  void _listen() async {
    if (!isListen) {
      bool available = await _speech.initialize(
        onStatus: (val) => log('onStatus: $val'),
        onError: (val) => log('onError: $val'),
      );
      debugPrint('Speech recognition available: $available');
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleMessages = _messages
        .where((message) => message.content.trim().isNotEmpty)
        .toList();

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              tooltip: 'New chat',
              onPressed: _isThinking ? null : _startNewChat,
              icon: const Icon(Icons.add_comment_outlined),
            ),
          ],
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
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DrawerHeader(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      'Chat history',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('New chat'),
                  enabled: !_isThinking,
                  onTap: _isThinking
                      ? null
                      : () => _startNewChat(closeDrawer: true),
                ),
                if (_historyError != null)
                  ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: Text(_historyError!),
                    trailing: IconButton(
                      tooltip: 'Retry loading history',
                      onPressed: _loadHistory,
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                const Divider(),
                Expanded(
                  child: _conversations.isEmpty
                      ? const Center(child: Text('No conversations yet'))
                      : ListView.builder(
                          itemCount: _conversations.length,
                          itemBuilder: (context, index) {
                            final conversation = _conversations[index];
                            final id = conversation['id'] as int;
                            return ListTile(
                              leading: const Icon(Icons.chat_bubble_outline),
                              title: Text(
                                conversation['title'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              selected: id == _currentConversationId,
                              enabled: !_isThinking,
                              onTap: _isThinking
                                  ? null
                                  : () => _selectConversation(id),
                              trailing: IconButton(
                                tooltip: 'Delete conversation',
                                onPressed: _isThinking
                                    ? null
                                    : () => _deleteConversation(id),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            if (_historyError != null)
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
                      Icons.history_toggle_off,
                      color: Color(0xFF9A5B00),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _historyError!,
                        style: const TextStyle(color: Color(0xFF684000)),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadHistory,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            if (_isHistoryReady && _messages.isEmpty && _historyError == null)
              Expanded(
                child: ChatEmptyWidget(
                  onPromptSelected: (prompt) {
                    _controller
                      ..text = prompt
                      ..selection = TextSelection.collapsed(
                        offset: prompt.length,
                      );
                  },
                ),
              )
            else
              // Messages list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 20,
                  ),
                  itemCount:
                      visibleMessages.length +
                      (_isThinking && !_hasResponseStarted ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == visibleMessages.length) {
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
                    final message = visibleMessages[index];
                    final isMe = message.role == 'user';

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
                                message.content,
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
                        decoration: InputDecoration(
                          hintText: 'Message Pocket AI...',
                          hintStyle: TextStyle(color: Color(0xFF9299A8)),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                          suffix: IconButton(
                            tooltip: 'Send voice message',
                            icon: Icon(
                              isListen ? Icons.mic : Icons.mic_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              _listen();
                            },
                          ),
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
                        _isThinking
                            ? Icons.hourglass_top_rounded
                            : Icons.arrow_upward_rounded,
                        color: Colors.white,
                      ),
                      onPressed:
                          (_modelReady && _isHistoryReady && !_isThinking)
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
