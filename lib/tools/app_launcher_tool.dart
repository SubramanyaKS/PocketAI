import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'pocket_tool.dart';

/// Offline tool to launch popular installed applications on Android.
class AppLauncherTool implements PocketTool {
  const AppLauncherTool();

  @override
  String get name => 'app_launcher';

  @override
  Map<String, dynamic> get definition => {
        "name": name,
        "description":
            "Launches installed applications like Camera, YouTube, Maps, WhatsApp, Chrome/Browser, Gallery, Gmail, Calendar, Phone dialer, Messages, or Spotify.",
        "parameters": {
          "type": "object",
          "properties": {
            "app": {
              "type": "string",
              "enum": [
                "camera",
                "youtube",
                "maps",
                "whatsapp",
                "browser",
                "gallery",
                "email",
                "calendar",
                "dialer",
                "messages",
                "spotify"
              ],
              "description": "The application to launch"
            }
          },
          "required": ["app"]
        }
      };

  @override
  Future<String?> tryExecute(String prompt) async {
    final app = matchApp(prompt);
    if (app == null) return null;
    return await launchApp(app);
  }

  /// Matches user prompts to supported applications.
  static String? matchApp(String query) {
    final text = query
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[?!.]+$'), '')
        .trim();

    // Guard against general questions
    if (text.startsWith('what') ||
        text.startsWith('how') ||
        text.startsWith('why') ||
        text.startsWith('tell me') ||
        text.startsWith('who')) {
      return null;
    }

    // Camera actions
    if (text == 'take a photo' ||
        text == 'take a picture' ||
        text == 'open camera' ||
        text == 'launch camera' ||
        text == 'start camera') {
      return 'camera';
    }

    // Standard launch pattern: "open ...", "launch ...", "start ..."
    final match = RegExp(r'^(?:open|launch|start)\s+(.+)$').firstMatch(text);
    if (match == null) return null;

    final target = match.group(1)!.trim();

    if (target == 'youtube' || target == 'yt') return 'youtube';
    if (target == 'maps' ||
        target == 'google maps' ||
        target == 'navigation') {
      return 'maps';
    }
    if (target == 'whatsapp' || target == 'whats app') return 'whatsapp';
    if (target == 'chrome' ||
        target == 'browser' ||
        target == 'google chrome' ||
        target == 'web browser' ||
        target == 'google') {
      return 'browser';
    }
    if (target == 'photos' ||
        target == 'gallery' ||
        target == 'google photos' ||
        target == 'photo album') {
      return 'gallery';
    }
    if (target == 'gmail' || target == 'email' || target == 'mail') {
      return 'email';
    }
    if (target == 'calendar' || target == 'google calendar') {
      return 'calendar';
    }
    if (target == 'phone' ||
        target == 'dialer' ||
        target == 'phone dialer' ||
        target == 'phone app') {
      return 'dialer';
    }
    if (target == 'messages' ||
        target == 'sms' ||
        target == 'messaging' ||
        target == 'text messages') {
      return 'messages';
    }
    if (target == 'spotify' || target == 'music') {
      return 'spotify';
    }
    if (target == 'camera') {
      return 'camera';
    }

    return null;
  }

  /// Dispatches the Android Intent to open the requested application.
  static Future<String> launchApp(String app) async {
    AndroidIntent? intent;
    String label;

    switch (app) {
      case 'camera':
        intent = const AndroidIntent(
          action: 'android.media.action.IMAGE_CAPTURE',
        );
        label = 'Camera';
        break;

      case 'youtube':
        intent = const AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'https://www.youtube.com',
          package: 'com.google.android.youtube',
        );
        label = 'YouTube';
        break;

      case 'maps':
        intent = const AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'geo:0,0?q=',
          package: 'com.google.android.apps.maps',
        );
        label = 'Maps';
        break;

      case 'whatsapp':
        intent = const AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: 'com.whatsapp',
          category: 'android.intent.category.LAUNCHER',
        );
        label = 'WhatsApp';
        break;

      case 'browser':
        intent = const AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'https://www.google.com',
          category: 'android.intent.category.BROWSABLE',
        );
        label = 'Browser';
        break;

      case 'gallery':
        intent = const AndroidIntent(
          action: 'android.intent.action.VIEW',
          type: 'image/*',
        );
        label = 'Gallery';
        break;

      case 'email':
        intent = const AndroidIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_EMAIL',
        );
        label = 'Email';
        break;

      case 'calendar':
        intent = const AndroidIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_CALENDAR',
        );
        label = 'Calendar';
        break;

      case 'dialer':
        intent = const AndroidIntent(
          action: 'android.intent.action.DIAL',
        );
        label = 'Phone dialer';
        break;

      case 'messages':
        intent = const AndroidIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_MESSAGING',
        );
        label = 'Messages';
        break;

      case 'spotify':
        intent = const AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: 'com.spotify.music',
          category: 'android.intent.category.LAUNCHER',
        );
        label = 'Spotify';
        break;

      default:
        return 'App "$app" is not supported.';
    }

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await intent.launch();
        return '🚀 Launching $label...';
      } catch (e) {
        debugPrint('Failed to launch $label: $e');
        return 'Could not open $label. It might not be installed on this device.';
      }
    }

    return '🚀 Launching $label (simulation on non-Android platform).';
  }
}
