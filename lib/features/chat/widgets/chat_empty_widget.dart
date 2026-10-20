import 'package:flutter/material.dart';
import 'package:pocket_ai/features/chat/widgets/prompt_suggestion.dart';

class ChatEmptyWidget extends StatelessWidget {
  const ChatEmptyWidget({super.key, required this.onPromptSelected});

  final ValueChanged<String> onPromptSelected;

  static const _suggestions = [
    ('Explain a concept simply', Icons.lightbulb_outline_rounded),
    ('Help me brainstorm ideas', Icons.auto_awesome_outlined),
    ('Write a short story', Icons.edit_note_rounded),
  ];

  @override
  Widget build(BuildContext context) {
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
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: Color(0xFF4F46E5),
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Welcome to Pocket AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF20283A),
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your private, offline assistant is ready. Ask a question '
                      'or choose an idea to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF747B8C),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'TRY ASKING',
                      style: TextStyle(
                        color: Color(0xFF9299A8),
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
