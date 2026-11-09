import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arivu_ai/features/chat/widgets/code_block_widget.dart';
import 'package:arivu_ai/features/chat/widgets/markdown_code_builder.dart';

void main() {
  testWidgets('Renders Markdown with CodeBlockWidget for code blocks', (tester) async {
    const markdownData = '''
# Markdown Test
Here is some **bold text** and `inline_code`.

```dart
void main() {
  print("Hello Arivu AI");
}
```
''';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownBody(
            data: markdownData,
            builders: {
              'code': CodeElementBuilder(isDark: true),
            },
          ),
        ),
      ),
    );

    // Verify elements rendered
    expect(find.text('Markdown Test'), findsOneWidget);
    expect(find.byType(CodeBlockWidget), findsOneWidget);
    expect(find.text('Dart'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
  });
}
