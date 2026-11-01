import 'package:flutter/material.dart';
import 'package:pocket_ai/features/chat/widgets/prompt_suggestion.dart';

class ChatEmptyWidget extends StatelessWidget {
  const ChatEmptyWidget({super.key, required this.onPromptSelected});

  final ValueChanged<String> onPromptSelected;

  static const _suggestions = [
    ('Explain quantum computing like I\'m 10', Icons.lightbulb_outline_rounded),
    ('Give me 3 healthy quick breakfast ideas', Icons.restaurant_menu_rounded),
    ('Write a 4-line poem about space', Icons.auto_awesome_rounded),
    ('How does offline AI work on a phone?', Icons.smart_toy_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: Color(0xFF4F46E5),
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Welcome to Pocket AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF20283A),
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your private, offline assistant is ready. Ask a question '
                      'or choose an idea to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF747B8C),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'TRY ASKING',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF9299A8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final (label, icon) in _suggestions)
                          PromptSuggestion(
                            label: label,
                            icon: icon,
                            onTap: () => onPromptSelected(label),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
