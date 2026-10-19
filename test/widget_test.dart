import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ai/app.dart';

void main() {
  testWidgets('shows the model setup screen on app launch', (tester) async {
    await tester.pumpWidget(const PocketAiApp());

    expect(find.text('Prepare Pocket AI'), findsOneWidget);
    expect(find.text('Checking for AI model...'), findsOneWidget);
  });
}
