import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arivu_ai/utils/app_error_widget.dart';

void main() {
  testWidgets('GlobalAppErrorWidget renders user-friendly error UI and details',
      (tester) async {
    final details = FlutterErrorDetails(
      exception: Exception('Test layout overflow exception'),
      stack: StackTrace.current,
      library: 'rendering library',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GlobalAppErrorWidget(details: details),
      ),
    );

    // Verify friendly user-facing header and explanation
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(
      find.text(
        'An unexpected interface error occurred. Your conversations, '
        'models, and local data remain safe on your device.',
      ),
      findsOneWidget,
    );
    expect(find.text('Reload App'), findsOneWidget);

    // Verify technical details accordion
    expect(find.text('Technical details'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

    // Expand accordion
    await tester.tap(find.text('Technical details'));
    await tester.pumpAndSettle();

    // Verify error detail text and copy button are revealed
    expect(find.textContaining('Test layout overflow exception'), findsOneWidget);
    expect(find.text('Copy error'), findsOneWidget);
  });
}
