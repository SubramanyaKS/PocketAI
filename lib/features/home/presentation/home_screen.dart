import 'package:flutter/material.dart';
import 'package:pocket_ai/features/assistant/presentation/voice_assistant_screen.dart';
import 'package:pocket_ai/features/chat/presentation/chat_screen.dart';
import 'package:pocket_ai/features/chat/service/local_ai_service.dart';

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
    const VoiceAssistantScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              spreadRadius: 0,
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.mic),
                activeIcon: Icon(Icons.mic),
                label: 'VoiceAssistant',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
