import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ai/features/chat/service/think_filter.dart';

void main() {
  group('ThinkFilter', () {
    test('removes leading blank lines before the answer', () {
      final filter = ThinkFilter();

      final firstChunk = filter.process('\n\n  The answer');
      final remaining = filter.finish();

      expect('$firstChunk$remaining', 'The answer');
    });

    test('removes thought content when tags are split across chunks', () {
      final filter = ThinkFilter();

      final output = [
        filter.process('<thi'),
        filter.process('nk>private reasoning</thi'),
        filter.process('nk>\n\nFinal answer.'),
        filter.finish(),
      ].join();

      expect(output, 'Final answer.');
    });

    test('preserves whitespace after the answer begins', () {
      final filter = ThinkFilter();

      final output = [
        filter.process('  First line'),
        filter.process('\n\nSecond line'),
        filter.finish(),
      ].join();

      expect(output, 'First line\n\nSecond line');
    });

    test('discards an unfinished thought at end of stream', () {
      final filter = ThinkFilter();

      final output = [
        filter.process('Visible answer <think>private reasoning'),
        filter.finish(),
      ].join();

      expect(output, 'Visible answer ');
    });
  });
}
