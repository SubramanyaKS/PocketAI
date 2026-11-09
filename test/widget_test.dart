import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arivu_ai/app.dart';

void main() {
  testWidgets('shows the model setup screen on app launch', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ArivuAiApp(),
      ),
    );

    expect(find.text('Prepare Arivu AI'), findsOneWidget);
    expect(find.text('Checking for AI model...'), findsOneWidget);
  });
}
