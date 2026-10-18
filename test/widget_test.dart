import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ai/app.dart';

void main() {
  testWidgets('shows the Pocket AI landing screen', (tester) async {
    await tester.pumpWidget(const PocketAiApp());

    expect(find.text('Pocket AI'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
