import '../tools/remainder_tools.dart';

class ReminderIntentResult {
  final bool isReminder;
  final String title;
  final int delayMinutes;

  const ReminderIntentResult({
    required this.isReminder,
    this.title = '',
    this.delayMinutes = 0,
  });
}

class ReminderParser {
  /// Detects phrases like:
  /// - "remind me to call John in 5 minutes"
  /// - "set a reminder to buy groceries in 1 hour"
  /// - "remind me in 10 minutes to drink water"
  /// - "remind me to check the oven after 15 minutes"
  static ReminderIntentResult parse(String input) {
    final text = input.trim();
    if (text.isEmpty) return const ReminderIntentResult(isReminder: false);

    final lower = text.toLowerCase();
    if (!lower.contains('remind')) {
      return const ReminderIntentResult(isReminder: false);
    }

    int delayMinutes = 0;

    // Pattern A: "remind me to [action] in [X] minutes/hours"
    final regexA = RegExp(
      r'remind\s+(?:me\s+)?(?:to\s+)?(.+?)\s+(?:in|after)\s+(\d+)\s*(minute|min|hour|hr)s?',
      caseSensitive: false,
    );

    // Pattern B: "remind me in [X] minutes/hours to [action]"
    final regexB = RegExp(
      r'remind\s+(?:me\s+)?(?:in|after)\s+(\d+)\s*(minute|min|hour|hr)s?\s+(?:to\s+)?(.+)',
      caseSensitive: false,
    );

    String task = '';

    final matchA = regexA.firstMatch(text);
    if (matchA != null) {
      task = matchA.group(1)?.trim() ?? '';
      final num = int.tryParse(matchA.group(2) ?? '0') ?? 0;
      final unit = matchA.group(3)?.toLowerCase() ?? 'minute';
      delayMinutes = unit.startsWith('h') ? num * 60 : num;
    } else {
      final matchB = regexB.firstMatch(text);
      if (matchB != null) {
        final num = int.tryParse(matchB.group(1) ?? '0') ?? 0;
        final unit = matchB.group(2)?.toLowerCase() ?? 'minute';
        delayMinutes = unit.startsWith('h') ? num * 60 : num;
        task = matchB.group(3)?.trim() ?? '';
      }
    }

    if (delayMinutes > 0 && task.isNotEmpty) {
      // Clean leading verbs if present
      task = task.replaceFirst(RegExp(r'^(to\s+)', caseSensitive: false), '').trim();
      return ReminderIntentResult(
        isReminder: true,
        title: task,
        delayMinutes: delayMinutes,
      );
    }

    return const ReminderIntentResult(isReminder: false);
  }

  /// Executes the reminder intent and returns a natural conversational confirmation string.
  static Future<String?> tryExecuteReminder(String prompt) async {
    final result = parse(prompt);
    if (!result.isReminder) return null;

    await NotificationService.instance.createReminder(
      title: result.title,
      delayMinutes: result.delayMinutes,
    );

    final durationStr = result.delayMinutes >= 60
        ? '${result.delayMinutes ~/ 60} ${result.delayMinutes ~/ 60 == 1 ? "hour" : "hours"}'
        : '${result.delayMinutes} ${result.delayMinutes == 1 ? "minute" : "minutes"}';

    return "Got it! I've set a reminder to ${result.title} in $durationStr.";
  }
}
