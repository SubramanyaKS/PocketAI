import '../models/chat_message.dart';

class ChatUtils {
  ChatUtils._();

  /// Generates a truncated title from the first prompt (max 48 runes).
  static String formatConversationTitle(String prompt) {
    final characters = prompt.runes.toList();
    if (characters.length <= 48) return prompt;
    return '${String.fromCharCodes(characters.take(48))}...';
  }

  /// Builds context window history ensuring character and message limits are respected.
  static List<ChatMessage> buildContextMessages({
    required List<ChatMessage> messages,
    required String prompt,
    required ChatMessage currentMessage,
    int maxInputCharacters = 3000,
    int maxHistoryMessages = 6,
  }) {
    var remainingHistoryCharacters = maxInputCharacters - prompt.runes.length;
    final history = <ChatMessage>[];
    final previousMessages =
        messages.isEmpty ? <ChatMessage>[] : messages.take(messages.length - 1).toList();

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
}
