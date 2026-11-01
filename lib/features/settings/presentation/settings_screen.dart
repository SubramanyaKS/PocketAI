import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_ai/provider/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          Text(
            'APPEARANCE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: currentTheme,
                  title: const Text('System Default'),
                  subtitle: const Text('Follows system dark/light mode'),
                  secondary: const Icon(Icons.settings_brightness_rounded),
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(themeProvider.notifier).setTheme(mode);
                    }
                  },
                ),
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: currentTheme,
                  title: const Text('Light Mode'),
                  subtitle: const Text('Clean and bright theme'),
                  secondary: const Icon(Icons.light_mode_rounded),
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(themeProvider.notifier).setTheme(mode);
                    }
                  },
                ),
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: currentTheme,
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Deep OLED dark theme'),
                  secondary: const Icon(Icons.dark_mode_rounded),
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(themeProvider.notifier).setTheme(mode);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'ABOUT POCKET AI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Offline & Private',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'All chat data and AI computation stay strictly on your device.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Keep backwards-compatibility in case imported as SeetingsScreen
typedef SeetingsScreen = SettingsScreen;
