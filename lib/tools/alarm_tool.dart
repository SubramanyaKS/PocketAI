import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'pocket_tool.dart';

class AlarmTimerTool implements PocketTool {
  const AlarmTimerTool();

  @override
  String get name => 'set_alarm_or_timer';

  @override
  Map<String, dynamic> get definition => {
        "name": name,
        "description":
            "Sets, dismisses, or stops an alarm or countdown timer using the phone's native Clock app.",
        "parameters": {
          "type": "object",
          "properties": {
            "action": {
              "type": "string",
              "enum": [
                "set_alarm",
                "set_timer",
                "dismiss_alarm",
                "dismiss_timer",
                "show_alarms"
              ],
              "description": "The clock action to perform",
            },
            "hour": {
              "type": "integer",
              "description": "Hour of the alarm (0-23)",
            },
            "minute": {
              "type": "integer",
              "description": "Minute of the alarm (0-59)",
            },
            "seconds": {
              "type": "integer",
              "description": "Duration of the timer in seconds",
            },
            "message": {
              "type": "string",
              "description": "Label or message for the alarm/timer",
            }
          },
          "required": ["action"],
        },
      };

  /// Parses natural language alarm and timer requests:
  /// - "set an alarm for 7:30 AM" / "wake me up at 6 AM" / "set an alarm for 6.25 PM"
  /// - "stop the alarm" / "dismiss alarm" / "cancel alarm" / "turn off the alarm"
  /// - "set a timer for 15 minutes" / "10 minute timer"
  /// - "stop the timer" / "cancel timer" / "turn off timer"
  /// - "show alarms" / "open clock"
  static Future<String?> tryExecuteAlarmOrTimer(String prompt) async {
    // Normalize all variations of PM/AM (p.m., p.m, p. m., pm) from voice dictation
    String cleaned = prompt
        .trim()
        .replaceAll(RegExp(r'\bp\.?\s*m\.?(?:\s|$|[.!?,;])', caseSensitive: false), 'pm ')
        .replaceAll(RegExp(r'\ba\.?\s*m\.?(?:\s|$|[.!?,;])', caseSensitive: false), 'am ')
        .replaceAll(RegExp(r'[.!?,;]+$'), '')
        .trim();
    final lower = cleaned.toLowerCase();

    // 1. Check dismiss / stop timer requests
    final stopTimerPattern = RegExp(
      r'\b(?:stop|cancel|dismiss|turn\s+off|clear|reset)\s+(?:the\s+)?timer(?:s)?\b',
      caseSensitive: false,
    );
    if (stopTimerPattern.hasMatch(lower)) {
      return await dismissNativeTimer();
    }

    // 2. Check dismiss / stop alarm requests
    final stopAlarmPattern = RegExp(
      r'\b(?:stop|cancel|dismiss|turn\s+off|silence|disable)\s+(?:the\s+)?alarm(?:s)?\b',
      caseSensitive: false,
    );
    if (stopAlarmPattern.hasMatch(lower)) {
      return await dismissNativeAlarm();
    }

    // 3. Check show / open alarms requests
    final showAlarmPattern = RegExp(
      r'\b(?:show|open|view|display)\s+(?:my\s+)?(?:alarms|clock)\b',
      caseSensitive: false,
    );
    if (showAlarmPattern.hasMatch(lower)) {
      return await showNativeAlarms();
    }

    // 4. Check set timer: "timer for 15 minutes", "set a 10 min timer"
    final timerPattern = RegExp(
      r'(?:set\s+(?:a\s+)?)?(\d+)\s*(minute|min|sec|second|hour|hr)s?\s+timer|timer\s+(?:for\s+)?(\d+)\s*(minute|min|sec|second|hour|hr)s?',
      caseSensitive: false,
    );

    final timerMatch = timerPattern.firstMatch(lower);
    if (timerMatch != null || lower.contains('timer')) {
      int seconds = 0;
      if (timerMatch != null) {
        final valStr = timerMatch.group(1) ?? timerMatch.group(3) ?? '0';
        final unitStr = timerMatch.group(2) ?? timerMatch.group(4) ?? 'minute';
        final val = int.tryParse(valStr) ?? 0;

        if (unitStr.startsWith('sec')) {
          seconds = val;
        } else if (unitStr.startsWith('h')) {
          seconds = val * 3600;
        } else {
          seconds = val * 60;
        }
      }

      if (seconds > 0) {
        return await setNativeTimer(
          seconds: seconds,
          message: 'Pocket AI Timer',
        );
      }
    }

    // 5. Check set alarm: handles ":", ".", or space between hour and minute, and various meridian expressions
    // e.g. "set an alarm for 6.25 PM", "wake me up at 6:00", "alarm for 8 pm", "wake me up at 6 in the morning"
    final alarmPattern = RegExp(
      r'(?:(?:set\s+(?:an?\s+)?)?alarm(?:\s+(?:for|at))?|wake\s+me\s+up(?:\s+at)?)\s+(\d{1,2})(?:[:.](\d{1,2})|\s+(\d{2}))?\s*(am|pm|in\s+the\s+morning|in\s+the\s+afternoon|in\s+the\s+evening|at\s+night|tonight)?',
      caseSensitive: false,
    );

    final match = alarmPattern.firstMatch(lower);
    if (match != null) {
      int hour = int.tryParse(match.group(1) ?? '') ?? 0;
      final minuteStr = match.group(2) ?? match.group(3);
      int minute = minuteStr != null ? (int.tryParse(minuteStr) ?? 0) : 0;
      final meridianRaw = match.group(4)?.toLowerCase();

      final isPm = meridianRaw != null &&
          (meridianRaw == 'pm' ||
              meridianRaw.contains('evening') ||
              meridianRaw.contains('afternoon') ||
              meridianRaw.contains('night'));
      final isAm = meridianRaw != null &&
          (meridianRaw == 'am' || meridianRaw.contains('morning'));

      if (isPm && hour < 12) {
        hour += 12;
      } else if (isAm && hour == 12) {
        hour = 0;
      }

      final displayTime =
          '${hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)}:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';

      return await setNativeAlarm(
        hour: hour,
        minute: minute,
        message: 'Pocket AI Alarm',
        formattedTime: displayTime,
      );
    }

    return null;
  }

  /// Triggers Android native AlarmClock.ACTION_DISMISS_ALARM intent
  static Future<String> dismissNativeAlarm() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.DISMISS_ALARM',
          arguments: <String, dynamic>{
            'android.intent.extra.alarm.SEARCH_MODE': 'android.next',
            'android.intent.extra.alarm.SKIP_UI': true,
          },
        );
        await intent.launch();
        return "Alarm dismissed in your Clock app.";
      } catch (e) {
        debugPrint('Failed to dismiss native alarm: $e');
        try {
          final fallbackIntent = AndroidIntent(
            action: 'android.intent.action.SHOW_ALARMS',
          );
          await fallbackIntent.launch();
          return "Opened Clock app alarms for you.";
        } catch (_) {
          return "Could not open the Clock app to dismiss the alarm.";
        }
      }
    }

    return "Alarm dismissed (simulation on non-Android platform).";
  }

  /// Triggers Android native AlarmClock.ACTION_DISMISS_TIMER intent
  static Future<String> dismissNativeTimer() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.DISMISS_TIMER',
          arguments: <String, dynamic>{
            'android.intent.extra.alarm.SKIP_UI': true,
          },
        );
        await intent.launch();
        return "Timer dismissed in your Clock app.";
      } catch (e) {
        debugPrint('Failed to dismiss native timer: $e');
        return "Could not open the Clock app to dismiss the timer.";
      }
    }

    return "Timer dismissed (simulation on non-Android platform).";
  }

  /// Opens the native Clock app alarms list
  static Future<String> showNativeAlarms() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.SHOW_ALARMS',
        );
        await intent.launch();
        return "Opening your Clock alarms.";
      } catch (e) {
        debugPrint('Failed to open alarms: $e');
        return "Could not open your Clock app.";
      }
    }

    return "Showing alarms (simulation on non-Android platform).";
  }

  /// Triggers Android native AlarmClock.ACTION_SET_ALARM intent
  static Future<String> setNativeAlarm({
    required int hour,
    required int minute,
    String message = 'Pocket AI Alarm',
    String? formattedTime,
  }) async {
    final display = formattedTime ??
        '${hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)}:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.SET_ALARM',
          arguments: <String, dynamic>{
            'android.intent.extra.alarm.HOUR': hour,
            'android.intent.extra.alarm.MINUTES': minute,
            'android.intent.extra.alarm.MESSAGE': message,
            'android.intent.extra.alarm.SKIP_UI': true,
          },
        );
        await intent.launch();
        return "Alarm set for $display in your phone's Clock app.";
      } catch (e) {
        debugPrint('Failed to set native alarm: $e');
        return "I tried to set the alarm for $display, but your Clock app could not be opened.";
      }
    }

    return "Alarm set for $display (simulation on non-Android platform).";
  }

  /// Triggers Android native AlarmClock.ACTION_SET_TIMER intent
  static Future<String> setNativeTimer({
    required int seconds,
    String message = 'Pocket AI Timer',
  }) async {
    final minutes = seconds ~/ 60;
    final remainingSecs = seconds % 60;
    final timeStr = minutes > 0
        ? '$minutes ${minutes == 1 ? "minute" : "minutes"}${remainingSecs > 0 ? " and $remainingSecs seconds" : ""}'
        : '$seconds seconds';

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.SET_TIMER',
          arguments: <String, dynamic>{
            'android.intent.extra.alarm.LENGTH': seconds,
            'android.intent.extra.alarm.MESSAGE': message,
            'android.intent.extra.alarm.SKIP_UI': true,
          },
        );
        await intent.launch();
        return "Timer started for $timeStr in your Clock app.";
      } catch (e) {
        debugPrint('Failed to set native timer: $e');
        return "I tried to start a $timeStr timer, but could not open the Clock app.";
      }
    }

    return "Timer started for $timeStr (simulation on non-Android platform).";
  }

  @override
  Future<String?> tryExecute(String prompt) => tryExecuteAlarmOrTimer(prompt);
}
