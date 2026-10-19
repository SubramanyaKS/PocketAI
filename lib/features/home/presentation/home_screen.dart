import 'package:flutter/material.dart';
import 'package:pocket_ai/features/model/presentation/model_setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 40),
            Column(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE0E7FF),
                  child: Icon(
                    Icons.smart_toy_rounded,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pocket AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const ModelSetupScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 12,
                  shadowColor: Colors.lightBlueAccent.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueAccent,
                  minimumSize: const Size.fromHeight(60),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                icon: const Icon(
                  Icons.chat,
                  size: 26,
                  color: Colors.blueAccent,
                ),
                label: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
