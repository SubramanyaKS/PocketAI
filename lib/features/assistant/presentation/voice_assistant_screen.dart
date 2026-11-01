import 'package:flutter/material.dart';

class VoiceAssistantScreen  extends StatefulWidget {
  const VoiceAssistantScreen ({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE0E7FF),
              child: Icon(Icons.smart_toy_rounded, color: Color(0xFF4F46E5)),
            ),
            const SizedBox(width: 12),
            Text(
              'Pocket AI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Text("Voice Assistant",style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172033),
                ),),

                Icon(Icons.waves),
                
            
          ],
        ),
      ),

    ));
  }
}