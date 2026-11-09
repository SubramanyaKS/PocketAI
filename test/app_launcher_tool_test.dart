import 'package:flutter_test/flutter_test.dart';
import 'package:arivu_ai/tools/app_launcher_tool.dart';
import 'package:arivu_ai/tools/tool_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLauncherTool Unit Tests', () {
    const tool = AppLauncherTool();

    test('Tool metadata and definition are valid', () {
      expect(tool.name, 'app_launcher');
      expect(tool.definition['name'], 'app_launcher');
      expect(tool.definition['parameters']['properties']['app'], isNotNull);
    });

    test('Matches Camera queries', () async {
      expect(await tool.tryExecute('open camera'), contains('Camera'));
      expect(await tool.tryExecute('launch camera'), contains('Camera'));
      expect(await tool.tryExecute('take a picture'), contains('Camera'));
      expect(await tool.tryExecute('take a photo'), contains('Camera'));
    });

    test('Matches YouTube and Spotify media apps', () async {
      expect(await tool.tryExecute('open youtube'), contains('YouTube'));
      expect(await tool.tryExecute('launch youtube'), contains('YouTube'));
      expect(await tool.tryExecute('open spotify'), contains('Spotify'));
    });

    test('Matches Maps and Navigation', () async {
      expect(await tool.tryExecute('open maps'), contains('Maps'));
      expect(await tool.tryExecute('open navigation'), contains('Maps'));
    });

    test('Matches Communication apps (WhatsApp, Phone, Messages, Email)', () async {
      expect(await tool.tryExecute('open whatsapp'), contains('WhatsApp'));
      expect(await tool.tryExecute('open phone'), contains('Phone dialer'));
      expect(await tool.tryExecute('open dialer'), contains('Phone dialer'));
      expect(await tool.tryExecute('open messages'), contains('Messages'));
      expect(await tool.tryExecute('open sms'), contains('Messages'));
      expect(await tool.tryExecute('open gmail'), contains('Email'));
      expect(await tool.tryExecute('open email'), contains('Email'));
    });

    test('Matches Browser, Photos, and Calendar', () async {
      expect(await tool.tryExecute('open chrome'), contains('Browser'));
      expect(await tool.tryExecute('open browser'), contains('Browser'));
      expect(await tool.tryExecute('open gallery'), contains('Gallery'));
      expect(await tool.tryExecute('open photos'), contains('Gallery'));
      expect(await tool.tryExecute('open calendar'), contains('Calendar'));
    });

    test('Rejects informational questions so LLM handles them', () async {
      expect(await tool.tryExecute('what is youtube?'), isNull);
      expect(await tool.tryExecute('how to take good photos with a camera'), isNull);
      expect(await tool.tryExecute('who founded whatsapp?'), isNull);
      expect(await tool.tryExecute('tell me a story'), isNull);
    });

    test('ToolRegistry dispatches app launch command correctly', () async {
      final res = await ToolRegistry.dispatch('open youtube');
      expect(res.handled, isTrue);
      expect(res.toolName, 'app_launcher');
      expect(res.reply, contains('YouTube'));
    });
  });
}
