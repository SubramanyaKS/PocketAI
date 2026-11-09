import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/chat_message.dart';

/// Service responsible for exporting and sharing chat conversations
/// as Markdown (.md) or formatted text.
class ChatExportService {
  ChatExportService._();

  static final ChatExportService instance = ChatExportService._();

  /// Converts a conversation and its messages into clean, formatted Markdown.
  String formatAsMarkdown({
    required String title,
    required List<ChatMessage> messages,
    DateTime? exportedAt,
  }) {
    final buffer = StringBuffer();
    final timestamp = (exportedAt ?? DateTime.now()).toLocal().toString().split('.')[0];

    buffer.writeln('# $title');
    buffer.writeln();
    buffer.writeln('> *Exported from Arivu AI on $timestamp*');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    for (final message in messages) {
      final isUser = message.role == 'user';
      final header = isUser ? '### 👤 User' : '### 🤖 Arivu AI';

      buffer.writeln(header);
      buffer.writeln();
      buffer.writeln(message.content.trim());
      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  /// Copies formatted conversation text directly to the system clipboard.
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Shares conversation text via system share sheet (e.g. Email, WhatsApp, Notes).
  Future<void> shareText({
    required String text,
    required String subject,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
      ),
    );
  }

  /// Creates a temporary .md file on disk and shares it via system share sheet.
  Future<File> createExportFile({
    required String title,
    required String markdown,
    Directory? directory,
  }) async {
    final targetDir = directory ?? await getTemporaryDirectory();
    final sanitizedTitle = title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    final fileName = 'arivu_ai_${sanitizedTitle.isEmpty ? "chat" : sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.md';
    final file = File('${targetDir.path}/$fileName');
    await file.writeAsString(markdown);
    return file;
  }

  /// Shares a generated file using the platform share sheet.
  Future<void> shareFile({
    required File file,
    required String subject,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: subject,
      ),
    );
  }
}
