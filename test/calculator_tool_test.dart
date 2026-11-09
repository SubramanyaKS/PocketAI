import 'package:flutter_test/flutter_test.dart';
import 'package:arivu_ai/tools/calculator_tool.dart';
import 'package:arivu_ai/tools/tool_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalculatorTool Unit Tests', () {
    const calc = CalculatorTool();

    test('Tool definition has valid metadata and schema', () {
      expect(calc.name, 'calculator');
      expect(calc.definition['name'], 'calculator');
      expect(calc.definition['parameters']['properties']['expression'], isNotNull);
    });

    test('Basic arithmetic evaluation', () async {
      expect(await calc.tryExecute('25 * 4'), contains('**100**'));
      expect(await calc.tryExecute('100 / 4'), contains('**25**'));
      expect(await calc.tryExecute('15 + 27'), contains('**42**'));
      expect(await calc.tryExecute('100 - 37'), contains('**63**'));
    });

    test('Order of operations (PEMDAS) and parentheses', () async {
      expect(await calc.tryExecute('3 + 5 * 2'), contains('**13**'));
      expect(await calc.tryExecute('(3 + 5) * 2'), contains('**16**'));
      expect(await calc.tryExecute('(10 + 20) / (2 + 3)'), contains('**6**'));
    });

    test('Floating point numbers and decimals', () async {
      expect(await calc.tryExecute('12.5 * 4'), contains('**50**'));
      expect(await calc.tryExecute('7.5 / 2'), contains('**3.75**'));
      expect(await calc.tryExecute('0.1 + 0.2'), contains('**0.3**'));
    });

    test('Powers, exponents, and square roots', () async {
      expect(await calc.tryExecute('2 ^ 8'), contains('**256**'));
      expect(await calc.tryExecute('2 to the power of 8'), contains('**256**'));
      expect(await calc.tryExecute('square root of 144'), contains('**12**'));
      expect(await calc.tryExecute('sqrt(81)'), contains('**9**'));
      expect(await calc.tryExecute('cbrt(27)'), contains('**3**'));
    });

    test('Natural language percentage queries', () async {
      expect(await calc.tryExecute('15% of 80'), contains('**12**'));
      expect(await calc.tryExecute('what is 15% of 80?'), contains('**12**'));
      expect(await calc.tryExecute('what is 20 percent of 150'), contains('**30**'));
      expect(await calc.tryExecute('calculate 50% of 90'), contains('**45**'));
    });

    test('Conversational prefix queries', () async {
      expect(await calc.tryExecute('what is 25 * 4?'), contains('**100**'));
      expect(await calc.tryExecute('what\'s 1500 / 12'), contains('**125**'));
      expect(await calc.tryExecute('calculate 120 + 45'), contains('**165**'));
      expect(await calc.tryExecute('how much is 500 / 4?'), contains('**125**'));
      expect(await calc.tryExecute('solve 10 * 10'), contains('**100**'));
    });

    test('Spoken voice word operations', () async {
      expect(await calc.tryExecute('25 times 4'), contains('**100**'));
      expect(await calc.tryExecute('100 divided by 4'), contains('**25**'));
      expect(await calc.tryExecute('50 minus 18'), contains('**32**'));
      expect(await calc.tryExecute('10 plus 25'), contains('**35**'));
      expect(await calc.tryExecute('12 multiplied by 5'), contains('**60**'));
    });

    test('Division by zero gracefully returns warning message', () async {
      final res = await calc.tryExecute('50 / 0');
      expect(res, contains('Cannot divide by zero'));
    });

    test('Rejects non-math queries so LLM handles them', () async {
      expect(await calc.tryExecute('what is the capital of France?'), isNull);
      expect(await calc.tryExecute('tell me a joke'), isNull);
      expect(await calc.tryExecute('how are you today?'), isNull);
      expect(await calc.tryExecute('turn on the flashlight'), isNull);
    });

    test('ToolRegistry dispatches math prompt correctly', () async {
      final result = await ToolRegistry.dispatch('what is 45 * 2?');
      expect(result.handled, isTrue);
      expect(result.toolName, 'calculator');
      expect(result.reply, contains('**90**'));
    });
  });
}
