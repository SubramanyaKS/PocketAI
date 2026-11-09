import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arivu_ai/features/chat/models/chat_message.dart';
import 'package:arivu_ai/features/chat/service/chat_export_service.dart';

void main() {
  group('ChatExportService Unit Tests', () {
    final exportService = ChatExportService.instance;

    test('formatAsMarkdown generates valid markdown document with roles and dividers', () {
      final messages = [
        ChatMessage(
          conversationId: 1,
          role: 'user',
          content: 'What is Arivu AI?',
          createdAt: DateTime(2026, 11, 9, 10, 0),
        ),
        ChatMessage(
          conversationId: 1,
          role: 'assistant',
          content: 'Arivu AI is an offline on-device AI assistant.',
          createdAt: DateTime(2026, 11, 9, 10, 1),
        ),
      ];

      final markdown = exportService.formatAsMarkdown(
        title: 'Project Overview',
        messages: messages,
        exportedAt: DateTime(2026, 11, 9, 10, 0),
      );

      expect(markdown, startsWith('# Project Overview'));
      expect(markdown, contains('Exported from Arivu AI on 2026-11-09 10:00:00'));
      expect(markdown, contains('---'));
      expect(markdown, contains('### 👤 User'));
      expect(markdown, contains('What is Arivu AI?'));
      expect(markdown, contains('### 🤖 Arivu AI'));
      expect(markdown, contains('Arivu AI is an offline on-device AI assistant.'));
    });

    test('formatAsMarkdown handles code blocks and special characters', () {
      final messages = [
        ChatMessage(
          conversationId: 2,
          role: 'user',
          content: 'Show me Dart code',
          createdAt: DateTime(2026, 11, 9, 12, 0),
        ),
        ChatMessage(
          conversationId: 2,
          role: 'assistant',
          content: '```dart\nvoid main() => print("Hello");\n```',
          createdAt: DateTime(2026, 11, 9, 12, 1),
        ),
      ];

      final markdown = exportService.formatAsMarkdown(
        title: 'Dart & Flutter Q&A',
        messages: messages,
        exportedAt: DateTime(2026, 11, 9, 12, 0),
      );

      expect(markdown, contains('```dart\nvoid main() => print("Hello");\n```'));
      expect(markdown, contains('### 🤖 Arivu AI'));
    });

    test('createExportFile creates and writes to a sanitized .md file on disk', () async {
      const title = 'Financial Report 2026 / Q3!';
      const markdown = '# Financial Report\nRevenue: \$10M';

      final file = await exportService.createExportFile(
        title: title,
        markdown: markdown,
        directory: Directory.systemTemp,
      );

      expect(await file.exists(), isTrue);
      expect(file.path.endsWith('.md'), isTrue);
      expect(file.path, contains('arivu_ai_financial_report_2026_q3'));

      final content = await file.readAsString();
      expect(content, equals(markdown));

      // Clean up
      if (await file.exists()) {
        await file.delete();
      }
    });
  });

  group('Conversation Search & Export Widget Tests', () {
    testWidgets('Drawer search bar filters items and displays matching snippets', (tester) async {
      final allConversations = [
        {
          'id': 1,
          'title': 'Flutter Architecture',
          'matching_snippet': null,
        },
        {
          'id': 2,
          'title': 'Offline Models',
          'matching_snippet': 'Qwen3 and SmolLM2 models run on CPU',
        },
        {
          'id': 3,
          'title': 'General Knowledge',
          'matching_snippet': null,
        },
      ];

      String currentQuery = '';
      List<Map<String, dynamic>> displayed = List.from(allConversations);

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                drawer: Drawer(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          key: const Key('search_field'),
                          decoration: InputDecoration(
                            hintText: 'Search chats & messages...',
                            suffixIcon: currentQuery.isNotEmpty
                                ? IconButton(
                                    key: const Key('clear_search'),
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      setState(() {
                                        currentQuery = '';
                                        displayed = List.from(allConversations);
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (val) {
                            setState(() {
                              currentQuery = val;
                              if (val.isEmpty) {
                                displayed = List.from(allConversations);
                              } else {
                                displayed = allConversations.where((c) {
                                  final title = (c['title'] as String).toLowerCase();
                                  final snippet = (c['matching_snippet'] as String?)?.toLowerCase() ?? '';
                                  return title.contains(val.toLowerCase()) || snippet.contains(val.toLowerCase());
                                }).toList();
                              }
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: displayed.isEmpty
                            ? Center(child: Text('No chats matching "$currentQuery"'))
                            : ListView.builder(
                                itemCount: displayed.length,
                                itemBuilder: (context, index) {
                                  final item = displayed[index];
                                  return ListTile(
                                    title: Text(item['title'] as String),
                                    subtitle: item['matching_snippet'] != null
                                        ? Text(item['matching_snippet'] as String)
                                        : null,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Check all 3 conversations are displayed initially
      expect(find.text('Flutter Architecture'), findsOneWidget);
      expect(find.text('Offline Models'), findsOneWidget);
      expect(find.text('General Knowledge'), findsOneWidget);
      expect(find.text('Qwen3 and SmolLM2 models run on CPU'), findsOneWidget);

      // Search for "SmolLM2" (matches snippet in conversation #2)
      await tester.enterText(find.byKey(const Key('search_field')), 'SmolLM2');
      await tester.pumpAndSettle();

      expect(find.text('Flutter Architecture'), findsNothing);
      expect(find.text('Offline Models'), findsOneWidget);
      expect(find.text('General Knowledge'), findsNothing);

      // Search for something non-existent
      await tester.enterText(find.byKey(const Key('search_field')), 'Quantum');
      await tester.pumpAndSettle();

      expect(find.text('No chats matching "Quantum"'), findsOneWidget);

      // Clear search via clear button
      await tester.tap(find.byKey(const Key('clear_search')));
      await tester.pumpAndSettle();

      expect(find.text('Flutter Architecture'), findsOneWidget);
      expect(find.text('General Knowledge'), findsOneWidget);
    });

    testWidgets('Export & Share popup menu renders action items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                PopupMenuButton<String>(
                  key: const Key('export_button'),
                  icon: const Icon(Icons.share_outlined),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share_text',
                      child: Text('Share Conversation'),
                    ),
                    const PopupMenuItem(
                      value: 'copy_markdown',
                      child: Text('Copy as Markdown'),
                    ),
                    const PopupMenuItem(
                      value: 'share_file',
                      child: Text('Export to .md File'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('export_button')), findsOneWidget);

      // Tap export button to open menu
      await tester.tap(find.byKey(const Key('export_button')));
      await tester.pumpAndSettle();

      expect(find.text('Share Conversation'), findsOneWidget);
      expect(find.text('Copy as Markdown'), findsOneWidget);
      expect(find.text('Export to .md File'), findsOneWidget);
    });
  });
}
