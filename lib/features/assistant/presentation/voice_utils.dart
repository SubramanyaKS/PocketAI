import 'package:flutter/material.dart';

enum AssistantState {
  idle,
  listening,
  thinking,
  speaking,
}

class VoiceUtils {
  VoiceUtils._();

  /// Checks if a streamed text snippet contains standard sentence endings.
  static bool containsSentenceEnding(String text) {
    return text.contains('.') || text.contains('?') || text.contains('!');
  }

  /// Strips formatting symbols like markdown asterisks, hashtags, and brackets
  /// so TTS reads clean, natural speech aloud.
  static String cleanSpokenText(String input) {
    return input
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'#+'), '')
        .replaceAll(RegExp(r'`+'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .trim();
  }

  /// Returns orb gradient colors based on the current assistant state.
  static List<Color> getGradients(AssistantState state, bool isDark) {
    switch (state) {
      case AssistantState.idle:
        return const [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)];
      case AssistantState.listening:
        return const [Color(0xFFEF4444), Color(0xFFF43F5E), Color(0xFFFB923C)];
      case AssistantState.thinking:
        return const [Color(0xFFF59E0B), Color(0xFFEAB308), Color(0xFF3B82F6)];
      case AssistantState.speaking:
        return const [Color(0xFF10B981), Color(0xFF06B6D4), Color(0xFF6366F1)];
    }
  }

  /// Returns the accent theme color for the assistant state.
  static Color getPrimaryColor(AssistantState state) {
    switch (state) {
      case AssistantState.idle:
        return const Color(0xFF6366F1);
      case AssistantState.listening:
        return const Color(0xFFEF4444);
      case AssistantState.thinking:
        return const Color(0xFFF59E0B);
      case AssistantState.speaking:
        return const Color(0xFF10B981);
    }
  }

  /// Returns the center button icon for the assistant state.
  static IconData getButtonIcon(AssistantState state) {
    switch (state) {
      case AssistantState.idle:
        return Icons.mic_rounded;
      case AssistantState.listening:
        return Icons.stop_rounded;
      case AssistantState.thinking:
        return Icons.auto_awesome_rounded;
      case AssistantState.speaking:
        return Icons.graphic_eq_rounded;
    }
  }

  /// Returns user guidance tips matching the current assistant state.
  static String getSubtitleTip(AssistantState state) {
    switch (state) {
      case AssistantState.idle:
        return 'Tap orb to start speaking';
      case AssistantState.listening:
        return 'Tap to finish & process';
      case AssistantState.thinking:
        return 'Analyzing & preparing reply...';
      case AssistantState.speaking:
        return 'Tap orb to interrupt';
    }
  }
}
