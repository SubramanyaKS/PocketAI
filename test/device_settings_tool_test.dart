import 'package:flutter_test/flutter_test.dart';
import 'package:arivu_ai/tools/device_settings_tool.dart';
import 'package:arivu_ai/tools/tool_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceSettingsTool Unit Tests', () {
    const tool = DeviceSettingsTool();

    test('Tool metadata and definition are valid', () {
      expect(tool.name, 'device_settings');
      expect(tool.definition['name'], 'device_settings');
      expect(tool.definition['parameters']['properties']['setting'], isNotNull);
    });

    test('Matches Wi-Fi queries', () async {
      expect(await tool.tryExecute('open wifi settings'), contains('Wi-Fi'));
      expect(await tool.tryExecute('open wi-fi'), contains('Wi-Fi'));
      expect(await tool.tryExecute('wifi settings'), contains('Wi-Fi'));
    });

    test('Matches Bluetooth queries', () async {
      expect(await tool.tryExecute('open bluetooth settings'), contains('Bluetooth'));
      expect(await tool.tryExecute('open bluetooth'), contains('Bluetooth'));
      expect(await tool.tryExecute('bluetooth settings'), contains('Bluetooth'));
    });

    test('Matches Display and Brightness queries', () async {
      expect(await tool.tryExecute('open display settings'), contains('Display'));
      expect(await tool.tryExecute('brightness settings'), contains('Display'));
      expect(await tool.tryExecute('screen settings'), contains('Display'));
    });

    test('Matches Sound and Volume queries', () async {
      expect(await tool.tryExecute('open sound settings'), contains('Sound & Volume'));
      expect(await tool.tryExecute('volume settings'), contains('Sound & Volume'));
      expect(await tool.tryExecute('audio settings'), contains('Sound & Volume'));
    });

    test('Matches Battery Saver settings without intercepting battery diagnostics', () async {
      expect(await tool.tryExecute('open battery settings'), contains('Battery Saver'));
      expect(await tool.tryExecute('battery saver settings'), contains('Battery Saver'));

      // Crucial: Diagnostics should NOT trigger DeviceSettingsTool!
      expect(await tool.tryExecute('check battery percentage'), isNull);
      expect(await tool.tryExecute('what is my battery level?'), isNull);
      expect(await tool.tryExecute('battery status'), isNull);
    });

    test('Matches Airplane mode and Location', () async {
      expect(await tool.tryExecute('open airplane mode'), contains('Airplane Mode'));
      expect(await tool.tryExecute('location settings'), contains('Location'));
    });

    test('Matches general phone settings', () async {
      expect(await tool.tryExecute('open settings'), contains('Device Settings'));
      expect(await tool.tryExecute('open phone settings'), contains('Device Settings'));
    });

    test('Rejects general questions so LLM handles them', () async {
      expect(await tool.tryExecute('what is wifi?'), isNull);
      expect(await tool.tryExecute('tell me about bluetooth security'), isNull);
      expect(await tool.tryExecute('how does airplane mode work'), isNull);
      expect(await tool.tryExecute('what is the capital of Japan?'), isNull);
    });

    test('ToolRegistry dispatches settings command correctly', () async {
      final res = await ToolRegistry.dispatch('open wifi settings');
      expect(res.handled, isTrue);
      expect(res.toolName, 'device_settings');
      expect(res.reply, contains('Wi-Fi'));
    });
  });
}
