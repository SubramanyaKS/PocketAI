import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'pocket_tool.dart';

enum TorchAction {
  turnOn,
  turnOff,
  toggle,
}

class TorchTool implements PocketTool {
  const TorchTool();

  @override
  String get name => 'torch_control';

  @override
  Map<String, dynamic> get definition => {
        "name": name,
        "description":
            "Controls the device flashlight / torch (turn on, turn off, or toggle)",
        "parameters": {
          "type": "object",
          "properties": {
            "action": {
              "type": "string",
              "enum": ["on", "off", "toggle"],
              "description": "Flashlight action to perform",
            }
          },
          "required": ["action"],
        },
      };

  static bool _isOn = false;
  static bool get isOn => _isOn;

  static Future<bool> isAvailable() async {
    try {
      return await TorchLight.isTorchAvailable();
    } catch (e) {
      debugPrint('Torch availability error: $e');
      return false;
    }
  }

  static Future<bool> turnOn() async {
    try {
      final available = await isAvailable();
      if (!available) return false;
      await TorchLight.enableTorch();
      _isOn = true;
      return true;
    } catch (e) {
      debugPrint('Unable to enable torch: $e');
      return false;
    }
  }

  static Future<bool> turnOff() async {
    try {
      await TorchLight.disableTorch();
      _isOn = false;
      return true;
    } catch (e) {
      debugPrint('Unable to disable torch: $e');
      return false;
    }
  }

  static Future<bool> toggle() async {
    return _isOn ? await turnOff() : await turnOn();
  }

  /// Parses flashlight / torch voice and text commands:
  /// - "turn on flashlight" / "turn on torch" / "flashlight on"
  /// - "turn off flashlight" / "turn off torch" / "flashlight off"
  /// - "toggle flashlight" / "toggle torch"
  static TorchAction? parseAction(String input) {
    final lower = input.trim().toLowerCase();
    final hasTorchKeyword = lower.contains('torch') ||
        lower.contains('flashlight') ||
        lower.contains('flash light');

    if (!hasTorchKeyword) return null;

    if (lower.contains('off') ||
        lower.contains('disable') ||
        lower.contains('stop') ||
        lower.contains('close')) {
      return TorchAction.turnOff;
    }

    if (lower.contains('on') ||
        lower.contains('enable') ||
        lower.contains('start') ||
        lower.contains('open')) {
      return TorchAction.turnOn;
    }

    if (lower.contains('toggle') || lower.contains('switch')) {
      return TorchAction.toggle;
    }

    return TorchAction.turnOn;
  }

  /// Executes torch intent and returns spoken / textual confirmation.
  static Future<String?> tryExecuteTorch(String prompt) async {
    final action = parseAction(prompt);
    if (action == null) return null;

    final available = await isAvailable();
    if (!available) {
      return "Sorry, flashlight is not available or supported on this device.";
    }

    switch (action) {
      case TorchAction.turnOn:
        final success = await turnOn();
        return success
            ? "Flashlight is now turned on."
            : "Could not turn on the flashlight.";
      case TorchAction.turnOff:
        final success = await turnOff();
        return success
            ? "Flashlight is now turned off."
            : "Could not turn off the flashlight.";
      case TorchAction.toggle:
        final success = await toggle();
        if (!success) return "Could not toggle the flashlight.";
        return _isOn
            ? "Flashlight is now turned on."
            : "Flashlight is now turned off.";
    }
  }

  @override
  Future<String?> tryExecute(String prompt) => tryExecuteTorch(prompt);
}

/// Backwards compatibility typedef
typedef TorchService = TorchTool;
