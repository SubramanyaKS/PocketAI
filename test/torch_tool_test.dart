import 'package:flutter_test/flutter_test.dart';
import 'package:arivu_ai/tools/torch_tool.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TorchTool Unit Tests', () {
    const tool = TorchTool();

    test('Tool metadata and definition are valid', () {
      expect(tool.name, 'torch_control');
      expect(tool.definition['name'], 'torch_control');
      expect(tool.definition['parameters']['properties']['action'], isNotNull);
    });

    test('Parses turn on flashlight commands', () {
      expect(TorchTool.parseAction('turn on flashlight'), TorchAction.turnOn);
      expect(TorchTool.parseAction('turn on torch'), TorchAction.turnOn);
      expect(TorchTool.parseAction('flashlight on'), TorchAction.turnOn);
      expect(TorchTool.parseAction('torch on'), TorchAction.turnOn);
      expect(TorchTool.parseAction('enable torch'), TorchAction.turnOn);
      expect(TorchTool.parseAction('start flashlight'), TorchAction.turnOn);
      expect(TorchTool.parseAction('open flash light'), TorchAction.turnOn);
    });

    test('Parses turn off flashlight commands', () {
      expect(TorchTool.parseAction('turn off flashlight'), TorchAction.turnOff);
      expect(TorchTool.parseAction('turn off torch'), TorchAction.turnOff);
      expect(TorchTool.parseAction('flashlight off'), TorchAction.turnOff);
      expect(TorchTool.parseAction('torch off'), TorchAction.turnOff);
      expect(TorchTool.parseAction('disable torch'), TorchAction.turnOff);
      expect(TorchTool.parseAction('stop flashlight'), TorchAction.turnOff);
      expect(TorchTool.parseAction('close flashlight'), TorchAction.turnOff);
    });

    test('Parses toggle flashlight commands', () {
      expect(TorchTool.parseAction('toggle flashlight'), TorchAction.toggle);
      expect(TorchTool.parseAction('toggle torch'), TorchAction.toggle);
      expect(TorchTool.parseAction('switch flashlight'), TorchAction.toggle);
      expect(TorchTool.parseAction('toggle the flash light'), TorchAction.toggle);
    });

    test('Rejects non-torch queries so LLM or other tools handle them', () {
      expect(TorchTool.parseAction('what is the weather today?'), isNull);
      expect(TorchTool.parseAction('tell me a joke'), isNull);
      expect(TorchTool.parseAction('open camera'), isNull);
      expect(TorchTool.parseAction('what time is it?'), isNull);
      expect(TorchTool.parseAction('how are you doing?'), isNull);
      expect(TorchTool.parseAction('set an alarm for 7 am'), isNull);
    });
  });
}
