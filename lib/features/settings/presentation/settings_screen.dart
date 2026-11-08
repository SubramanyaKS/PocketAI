// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_ai/features/chat/service/local_ai_service.dart';
import 'package:pocket_ai/features/settings/presentation/manage_models_screen.dart';
import 'package:pocket_ai/provider/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final LocalAiService? aiService;

  const SettingsScreen({super.key, this.aiService});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final LocalAiService _aiService;

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? LocalAiService.instance;
  }

  String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb >= 1000) {
      return '${(mb / 1024).toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeModel = _aiService.activeModel;

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
          // APPEARANCE SECTION
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
          Material(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
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
          ),

          const SizedBox(height: 32),

          // AI MODEL & STORAGE MANAGEMENT SECTION
          Text(
            'AI MODEL & STORAGE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  // Active Model Info Tile
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.memory_rounded,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            activeModel.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: FutureBuilder<int>(
                      future: _aiService.getTotalModelsSizeBytes(),
                      builder: (context, snapshot) {
                        final total = snapshot.data ?? 0;
                        return Text(
                          'Size: ${activeModel.sizeFormatted} • Total models on disk: ${_formatBytes(total)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                  // Navigation to Manage & Delete Models Screen
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_mode_rounded,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    title: const Text(
                      'Manage & Delete Models',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Switch models or delete downloaded files to free space',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ManageModelsScreen(aiService: _aiService),
                        ),
                      );
                      if (mounted) {
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ABOUT POCKET AI SECTION
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
