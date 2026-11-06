import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'code_block_widget.dart';

class CodeElementBuilder extends MarkdownElementBuilder {
  final bool isDark;

  CodeElementBuilder({required this.isDark});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = '';

    if (element.attributes['class'] != null) {
      final String lg = element.attributes['class'] as String;
      if (lg.startsWith('language-')) {
        language = lg.substring(9);
      }
    }

    final text = element.textContent.trimRight();

    // Check if it's a block-level code block (has language or multiple lines)
    final isBlock = language.isNotEmpty || text.contains('\n');

    if (!isBlock) {
      // Inline code styling: `code`
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
          ),
        ),
      );
    }

    return CodeBlockWidget(
      code: text,
      language: language,
      isDark: isDark,
    );
  }
}
