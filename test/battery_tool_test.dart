import 'package:flutter_test/flutter_test.dart';
import 'package:arivu_ai/tools/battery_tool.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BatteryTool Unit Tests', () {
    const tool = BatteryTool();

    test('Tool metadata and definition are valid', () {
      expect(tool.name, 'get_battery_info');
      expect(tool.definition['name'], 'get_battery_info');
      expect(tool.definition['description'], contains('battery'));
      expect(tool.definition['parameters']['properties'], isNotNull);
    });

    test('Identifies natural language battery queries', () {
      expect(BatteryTool.isBatteryQuery('what is my battery level'), isTrue);
      expect(BatteryTool.isBatteryQuery('check battery'), isTrue);
      expect(BatteryTool.isBatteryQuery('battery percentage'), isTrue);
      expect(BatteryTool.isBatteryQuery('how much battery is left?'), isTrue);
      expect(BatteryTool.isBatteryQuery('is my phone charging'), isTrue);
      expect(BatteryTool.isBatteryQuery('battery status'), isTrue);
      expect(BatteryTool.isBatteryQuery('battery'), isTrue);
      expect(BatteryTool.isBatteryQuery('check power level'), isTrue);
      expect(BatteryTool.isBatteryQuery('battery remaining'), isTrue);
    });

    test('Rejects non-battery queries so LLM or other tools handle them', () {
      expect(BatteryTool.isBatteryQuery('what is the capital of France?'), isFalse);
      expect(BatteryTool.isBatteryQuery('how do solar panels store energy?'), isFalse);
      expect(BatteryTool.isBatteryQuery('who invented electricity?'), isFalse);
      expect(BatteryTool.isBatteryQuery('tell me a joke'), isFalse);
      expect(BatteryTool.isBatteryQuery('open camera'), isFalse);
      expect(BatteryTool.isBatteryQuery('set an alarm for 7 am'), isFalse);
    });
  });
}
