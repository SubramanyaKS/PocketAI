import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:flutter_highlighter/themes/github.dart';

class CodeBlockWidget extends StatefulWidget {
  final String code;
  final String? language;
  final bool isDark;

  const CodeBlockWidget({
    super.key,
    required this.code,
    this.language,
    required this.isDark,
  });

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  bool _copied = false;

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  String _formatLanguageName(String lang) {
    if (lang.isEmpty) return 'Code';
    switch (lang) {
      case 'dart':
        return 'Dart';
      case 'python':
      case 'py':
        return 'Python';
      case 'javascript':
      case 'js':
        return 'JavaScript';
      case 'typescript':
      case 'ts':
        return 'TypeScript';
      case 'html':
        return 'HTML';
      case 'css':
        return 'CSS';
      case 'json':
        return 'JSON';
      case 'bash':
      case 'sh':
        return 'Bash';
      case 'sql':
        return 'SQL';
      case 'cpp':
      case 'c++':
        return 'C++';
      case 'c':
        return 'C';
      case 'java':
        return 'Java';
      case 'kotlin':
        return 'Kotlin';
      case 'swift':
        return 'Swift';
      case 'rust':
        return 'Rust';
      case 'go':
        return 'Go';
      case 'yaml':
      case 'yml':
        return 'YAML';
      case 'markdown':
      case 'md':
        return 'Markdown';
      default:
        return lang.length > 1
            ? lang[0].toUpperCase() + lang.substring(1)
            : lang.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = (widget.language ?? '').trim().toLowerCase();
    final displayLang = _formatLanguageName(lang);

    final bg = widget.isDark ? const Color(0xFF1E222B) : const Color(0xFFF1F5F9);
    final borderColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE2E8F0);
    final headerBg = widget.isDark
        ? const Color(0xFF181B22)
        : const Color(0xFFE2E8F0).withValues(alpha: 0.7);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Language & Copy Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            color: headerBg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.code_rounded,
                      size: 15,
                      color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      displayLang,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _copyToClipboard,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _copied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 13,
                        color: _copied
                            ? const Color(0xFF10B981)
                            : (widget.isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _copied ? 'Copied!' : 'Copy',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _copied
                              ? const Color(0xFF10B981)
                              : (widget.isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Code Area with Horizontal Scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: HighlightView(
              widget.code,
              language: lang.isEmpty ? 'plaintext' : lang,
              theme: widget.isDark ? atomOneDarkTheme : githubTheme,
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
