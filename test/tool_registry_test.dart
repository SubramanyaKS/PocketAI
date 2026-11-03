import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ai/tools/tool_registry.dart';
import 'package:pocket_ai/tools/alarm_tool.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ToolRegistry & AlarmTimerTool Tests', () {
    test('ToolRegistry has all registered tools', () {
      final names = ToolRegistry.tools.map((t) => t.name).toList();
      expect(names, contains('torch_control'));
      expect(names, contains('create_reminder'));
      expect(names, contains('get_battery_info'));
      expect(names, contains('set_alarm_or_timer'));
    });

    test('AlarmTimerTool parses alarm phrases (colons, dots, spaces, meridians)', () async {
      // Standard colon format
      final res1 = await AlarmTimerTool.tryExecuteAlarmOrTimer('set an alarm for 7:30 AM');
      expect(res1, isNotNull);
      expect(res1, contains('7:30 AM'));

      // User reported bug: dot separator with PM
      final res2 = await AlarmTimerTool.tryExecuteAlarmOrTimer('set an alarm for 6.25 PM');
      expect(res2, isNotNull);
      expect(res2, contains('6:25 PM'));

      // Dot separator lowercase
      final res3 = await AlarmTimerTool.tryExecuteAlarmOrTimer('set an alarm for 6.25 pm');
      expect(res3, isNotNull);
      expect(res3, contains('6:25 PM'));

      // Space separated STT
      final res4 = await AlarmTimerTool.tryExecuteAlarmOrTimer('set an alarm for 6 25 pm');
      expect(res4, isNotNull);
      expect(res4, contains('6:25 PM'));

      // Descriptive phrases
      final res5 = await AlarmTimerTool.tryExecuteAlarmOrTimer('wake me up at 6 in the morning');
      expect(res5, isNotNull);
      expect(res5, contains('6:00 AM'));

      final res6 = await AlarmTimerTool.tryExecuteAlarmOrTimer('wake me up at 8 tonight');
      expect(res6, isNotNull);
      expect(res6, contains('8:00 PM'));

      // Trailing punctuation and dotted p.m. from Android voice dictation
      final res7 = await AlarmTimerTool.tryExecuteAlarmOrTimer('set an alarm for 6.25 PM.');
      expect(res7, isNotNull);
      expect(res7, contains('6:25 PM'));

      final res8 = await AlarmTimerTool.tryExecuteAlarmOrTimer('set an alarm for 6.25 p.m.');
      expect(res8, isNotNull);
      expect(res8, contains('6:25 PM'));

      final res9 = await AlarmTimerTool.tryExecuteAlarmOrTimer('set an alarm for 6.25 p.m');
      expect(res9, isNotNull);
      expect(res9, contains('6:25 PM'));

      final res10 = await AlarmTimerTool.tryExecuteAlarmOrTimer('set an alarm for 6.25 p. m.');
      expect(res10, isNotNull);
      expect(res10, contains('6:25 PM'));

      final res11 = await AlarmTimerTool.tryExecuteAlarmOrTimer('set an alarm for 6.25 a.m.');
      expect(res11, isNotNull);
      expect(res11, contains('6:25 AM'));
    });

    test('AlarmTimerTool parses timer phrases', () async {
      final res1 = await AlarmTimerTool.tryExecuteAlarmOrTimer('set a timer for 15 minutes');
      expect(res1, isNotNull);
      expect(res1, contains('15 minutes'));

      final res2 = await AlarmTimerTool.tryExecuteAlarmOrTimer('30 second timer');
      expect(res2, isNotNull);
      expect(res2, contains('30 seconds'));
    });

    test('ToolRegistry dispatches unhandled input gracefully', () async {
      final res = await ToolRegistry.dispatch('What is quantum physics?');
      expect(res.handled, isFalse);
      expect(res.reply, isNull);
    });

    test('ToolRegistry dispatches alarm intent with dot separator', () async {
      final res = await ToolRegistry.dispatch('set an alarm for 6.25 PM');
      expect(res.handled, isTrue);
      expect(res.toolName, equals('set_alarm_or_timer'));
      expect(res.reply, contains('6:25 PM'));
    });
  });
}
