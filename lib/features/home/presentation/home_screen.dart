import 'package:flutter/material.dart';
import 'package:arivu_ai/features/assistant/presentation/voice_assistant_screen.dart';
import 'package:arivu_ai/features/chat/presentation/chat_screen.dart';
import 'package:arivu_ai/features/chat/service/local_ai_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.aiService});

  final LocalAiService aiService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = <Widget>[
    ChatScreen(aiService: widget.aiService),
    VoiceAssistantScreen(aiService: widget.aiService),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              spreadRadius: 0,
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            selectedItemColor: const Color(0xFF6366F1),
            unselectedItemColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                activeIcon: Icon(Icons.chat_bubble_rounded),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.graphic_eq_rounded),
                activeIcon: Icon(Icons.graphic_eq_rounded),
                label: 'Voice Assistant',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
