import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'pocket_tool.dart';

/// Offline tool to open system settings screens on Android.
class DeviceSettingsTool implements PocketTool {
  const DeviceSettingsTool();

  @override
  String get name => 'device_settings';

  @override
  Map<String, dynamic> get definition => {
        "name": name,
        "description":
            "Opens device system settings like Wi-Fi, Bluetooth, Display, Sound, Battery Saver, Airplane Mode, Location, or general Settings.",
        "parameters": {
          "type": "object",
          "properties": {
            "setting": {
              "type": "string",
              "enum": [
                "wifi",
                "bluetooth",
                "display",
                "sound",
                "battery",
                "airplane",
                "location",
                "settings"
              ],
              "description": "The setting screen to open"
            }
          },
          "required": ["setting"]
        }
      };

  @override
  Future<String?> tryExecute(String prompt) async {
    final setting = matchSetting(prompt);
    if (setting == null) return null;
    return await openSetting(setting);
  }

  /// Matches user prompts to supported system setting types.
  static String? matchSetting(String query) {
    final text = query
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[?!.]+$'), '')
        .trim();

    // Guard against battery queries that belong to BatteryTool
    if (text.contains('level') ||
        text.contains('percentage') ||
        text.contains('status') ||
        text.contains('how much battery') ||
        text.contains('check battery')) {
      return null;
    }

    // Guard against general questions
    if (text.startsWith('what') ||
        text.startsWith('tell me') ||
        text.startsWith('how') ||
        text.startsWith('why')) {
      return null;
    }

    // Wi-Fi
    if (RegExp(r'^(?:open|show|go to|view)?\s*(?:wi-?fi|wifi|wireless)\s*(?:settings|options)?$')
            .hasMatch(text) ||
        text == 'open wifi' ||
        text == 'open wi-fi' ||
        text == 'wifi settings' ||
        text == 'wi-fi settings') {
      return 'wifi';
    }

    // Bluetooth
    if (RegExp(r'^(?:open|show|go to|view)?\s*(?:bluetooth|bt)\s*(?:settings|options)?$')
            .hasMatch(text) ||
        text == 'open bluetooth' ||
        text == 'bluetooth settings') {
      return 'bluetooth';
    }

    // Display / Brightness
    if (RegExp(r'^(?:open|show|go to|view)?\s*(?:display|screen|brightness)\s*(?:settings|options)$')
            .hasMatch(text) ||
        text == 'display settings' ||
        text == 'brightness settings' ||
        text == 'screen settings' ||
        text == 'open display settings') {
      return 'display';
    }

    // Sound / Volume
    if (RegExp(r'^(?:open|show|go to|view)?\s*(?:sound|volume|audio)\s*(?:settings|options)$')
            .hasMatch(text) ||
        text == 'sound settings' ||
        text == 'volume settings' ||
        text == 'audio settings' ||
        text == 'open sound settings') {
      return 'sound';
    }

    // Battery Settings / Saver
    if (RegExp(r'^(?:open|show|go to)?\s*(?:battery\s+saver|power\s+saver|battery\s+settings)(?:\s+settings)?$')
            .hasMatch(text) ||
        text == 'battery settings' ||
        text == 'open battery settings') {
      return 'battery';
    }

    // Airplane mode
    if (RegExp(r'^(?:open|show|go to)?\s*(?:airplane|flight)\s*(?:mode|settings)$')
        .hasMatch(text)) {
      return 'airplane';
    }

    // Location / GPS
    if (RegExp(r'^(?:open|show|go to)?\s*(?:location|gps)\s*(?:settings|options)$')
        .hasMatch(text)) {
      return 'location';
    }

    // General Device Settings
    if (RegExp(r'^(?:open|launch|show|go to)\s+(?:phone\s+|device\s+|system\s+)?settings$')
            .hasMatch(text) ||
        text == 'device settings' ||
        text == 'phone settings' ||
        text == 'system settings') {
      return 'settings';
    }

    return null;
  }

  /// Dispatches the Android system intent corresponding to the requested setting.
  static Future<String> openSetting(String setting) async {
    String action;
    String label;

    switch (setting) {
      case 'wifi':
        action = 'android.settings.WIFI_SETTINGS';
        label = 'Wi-Fi settings';
        break;
      case 'bluetooth':
        action = 'android.settings.BLUETOOTH_SETTINGS';
        label = 'Bluetooth settings';
        break;
      case 'display':
        action = 'android.settings.DISPLAY_SETTINGS';
        label = 'Display settings';
        break;
      case 'sound':
        action = 'android.settings.SOUND_SETTINGS';
        label = 'Sound & Volume settings';
        break;
      case 'battery':
        action = 'android.settings.BATTERY_SAVER_SETTINGS';
        label = 'Battery Saver settings';
        break;
      case 'airplane':
        action = 'android.settings.AIRPLANE_MODE_SETTINGS';
        label = 'Airplane Mode settings';
        break;
      case 'location':
        action = 'android.settings.LOCATION_SOURCE_SETTINGS';
        label = 'Location settings';
        break;
      case 'settings':
      default:
        action = 'android.settings.SETTINGS';
        label = 'Device Settings';
        break;
    }

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final intent = AndroidIntent(action: action);
        await intent.launch();
        return '⚙️ Opening $label...';
      } catch (e) {
        debugPrint('Failed to open $label: $e');
        return 'Could not open $label on this device.';
      }
    }

    return '⚙️ Opening $label (simulation on non-Android platform).';
  }
}
