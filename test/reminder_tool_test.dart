import 'package:flutter_test/flutter_test.dart';
import 'package:arivu_ai/tools/reminder_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReminderTool & ReminderParser Unit Tests', () {
    const tool = ReminderTool();

    test('Tool metadata and definition are valid', () {
      expect(tool.name, 'create_reminder');
      expect(tool.definition['name'], 'create_reminder');
      expect(tool.definition['parameters']['properties']['title'], isNotNull);
      expect(tool.definition['parameters']['properties']['delay_minutes'], isNotNull);
    });

    test('Parses Pattern A: "remind me to [action] in [X] minutes"', () {
      final res1 = ReminderTool.parse('remind me to call John in 5 minutes');
      expect(res1.isReminder, isTrue);
      expect(res1.title, equals('call John'));
      expect(res1.delayMinutes, equals(5));

      final res2 = ReminderTool.parse('remind to drink water after 15 min');
      expect(res2.isReminder, isTrue);
      expect(res2.title, equals('drink water'));
      expect(res2.delayMinutes, equals(15));

      final res3 = ReminderTool.parse('remind me to check the oven in 1 hour');
      expect(res3.isReminder, isTrue);
      expect(res3.title, equals('check the oven'));
      expect(res3.delayMinutes, equals(60));

      final res4 = ReminderTool.parse('remind me to take medication in 2 hours');
      expect(res4.isReminder, isTrue);
      expect(res4.title, equals('take medication'));
      expect(res4.delayMinutes, equals(120));
    });

    test('Parses Pattern B: "remind me in [X] minutes to [action]"', () {
      final res1 = ReminderTool.parse('remind me in 10 minutes to drink water');
      expect(res1.isReminder, isTrue);
      expect(res1.title, equals('drink water'));
      expect(res1.delayMinutes, equals(10));

      final res2 = ReminderTool.parse('remind me after 30 mins to leave for meeting');
      expect(res2.isReminder, isTrue);
      expect(res2.title, equals('leave for meeting'));
      expect(res2.delayMinutes, equals(30));

      final res3 = ReminderTool.parse('remind me in 1 hr to call mom');
      expect(res3.isReminder, isTrue);
      expect(res3.title, equals('call mom'));
      expect(res3.delayMinutes, equals(60));
    });

    test('Rejects non-reminder and informational queries so LLM handles them', () {
      expect(ReminderTool.parse('').isReminder, isFalse);
      expect(ReminderTool.parse('what is a reminder?').isReminder, isFalse);
      expect(ReminderTool.parse('can you remind me what year it is?').isReminder, isFalse);
      expect(ReminderTool.parse('remind me why the sky is blue').isReminder, isFalse);
      expect(ReminderTool.parse('what is the capital of India?').isReminder, isFalse);
      expect(ReminderTool.parse('turn on the flashlight').isReminder, isFalse);
    });
  });
}
