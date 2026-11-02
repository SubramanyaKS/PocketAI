import 'package:battery_plus/battery_plus.dart';

class BatteryTool {
  static final Battery _battery = Battery();

  /// Retrieves raw battery info map.
  static Future<Map<String, dynamic>> getBatteryInfo() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;

      String status;
      switch (state) {
        case BatteryState.charging:
          status = 'Charging';
          break;
        case BatteryState.discharging:
          status = 'Discharging';
          break;
        case BatteryState.full:
          status = 'Fully charged';
          break;
        case BatteryState.connectedNotCharging:
          status = 'Connected, not charging';
          break;
        default:
          status = 'Not charging';
      }

      return {
        'success': true,
        'level': level,
        'status': status,
        'isCharging': state == BatteryState.charging,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to retrieve battery information: $e',
      };
    }
  }

  /// Parses natural language battery requests:
  /// - "what is my battery level" / "battery percentage"
  /// - "check battery" / "how much battery left"
  /// - "is my phone charging"
  static bool isBatteryQuery(String input) {
    final lower = input.trim().toLowerCase();
    final hasBatteryKeyword = lower.contains('battery') ||
        lower.contains('charging') ||
        lower.contains('power level');

    if (!hasBatteryKeyword) return false;

    return lower.contains('percentage') ||
        lower.contains('level') ||
        lower.contains('check') ||
        lower.contains('status') ||
        lower.contains('what') ||
        lower.contains('how much') ||
        lower.contains('is') ||
        lower.contains('left') ||
        lower.contains('remaining') ||
        lower == 'battery';
  }

  /// Executes battery check and returns natural spoken / chat response.
  static Future<String?> tryExecuteBattery(String prompt) async {
    if (!isBatteryQuery(prompt)) return null;

    final info = await getBatteryInfo();
    if (info['success'] != true) {
      return "Sorry, I am unable to check your device's battery right now.";
    }

    final level = info['level'] as int;
    final status = info['status'] as String;
    final isCharging = info['isCharging'] as bool;

    if (isCharging) {
      return "Your battery is at $level% and currently charging.";
    } else if (level == 100) {
      return "Your battery is fully charged at 100%.";
    } else if (level <= 15) {
      return "Your battery is low at $level% ($status). You might want to plug in your charger soon.";
    } else {
      return "Your battery is at $level% ($status).";
    }
  }
}
