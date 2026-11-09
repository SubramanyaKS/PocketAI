import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ai/features/document/models/attached_document.dart';
import 'package:pocket_ai/features/document/service/document_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  group('Document Model Tests', () {
    test('AttachedDocument calculates formatted size correctly', () {
      final docBytes = AttachedDocument(
        id: '1',
        name: 'test.txt',
        path: '/tmp/test.txt',
        sizeBytes: 512,
        fullText: 'Hello world',
        chunks: const [],
      );
      expect(docBytes.sizeFormatted, '512 B');

      final docKb = AttachedDocument(
        id: '2',
        name: 'report.pdf',
        path: '/tmp/report.pdf',
        sizeBytes: 2048,
        fullText: 'Report',
        chunks: const [],
      );
      expect(docKb.sizeFormatted, '2.0 KB');

      final docMb = AttachedDocument(
        id: '3',
        name: 'data.md',
        path: '/tmp/data.md',
        sizeBytes: 1048576 * 3,
        fullText: 'Data',
        chunks: const [],
      );
      expect(docMb.sizeFormatted, '3.0 MB');
    });

    test('AttachedDocument extracts file extension correctly', () {
      final pdfDoc = AttachedDocument(
        id: '1',
        name: 'my_contract.PDF',
        path: '',
        sizeBytes: 100,
        fullText: '',
        chunks: const [],
      );
      expect(pdfDoc.extension, 'pdf');

      final txtDoc = AttachedDocument(
        id: '2',
        name: 'notes.txt',
        path: '',
        sizeBytes: 100,
        fullText: '',
        chunks: const [],
      );
      expect(txtDoc.extension, 'txt');
    });

    test('DocumentChunk calculates estimated tokens', () {
      const chunk = DocumentChunk(
        index: 0,
        text: 'This is a test chunk containing approximately nine words.',
      );
      expect(chunk.index, 0);
      expect(chunk.tokenEstimate, (chunk.text.length / 4).ceil());
    });
  });

  group('DocumentService Extraction Tests', () {
    final service = DocumentService.instance;

    test('Extracts plain text from .txt and .md files', () {
      const rawString = '# Pocket AI\nLocal offline assistant.';
      final bytes = Uint8List.fromList(utf8.encode(rawString));

      final txtResult = service.extractText(name: 'notes.txt', bytes: bytes);
      expect(txtResult, equals(rawString));

      final mdResult = service.extractText(name: 'README.md', bytes: bytes);
      expect(mdResult, equals(rawString));
    });

    test('Extracts text from PDF files using syncfusion_flutter_pdf', () {
      final pdfDoc = PdfDocument();
      final page = pdfDoc.pages.add();
      page.graphics.drawString(
        'Offline RAG architecture for on-device privacy.',
        PdfStandardFont(PdfFontFamily.helvetica, 12),
      );
      final pdfBytes = Uint8List.fromList(pdfDoc.saveSync());
      pdfDoc.dispose();

      final extracted = service.extractText(name: 'doc.pdf', bytes: pdfBytes);
      expect(extracted, contains('Offline RAG architecture'));
      expect(extracted, contains('on-device privacy'));
    });
  });

  group('DocumentService Chunking Tests', () {
    final service = DocumentService.instance;

    test('Empty text produces empty chunks', () {
      expect(service.chunkText(''), isEmpty);
      expect(service.chunkText('   \n\n  '), isEmpty);
    });

    test('Short text produces a single chunk', () {
      const text = 'Pocket AI is a fully private offline assistant.';
      final chunks = service.chunkText(text, targetChunkChars: 300);

      expect(chunks.length, 1);
      expect(chunks.first.index, 0);
      expect(chunks.first.text, text);
    });

    test('Splits long text across paragraph and sentence boundaries', () {
      final paragraph1 = 'A' * 250;
      final paragraph2 = 'B' * 250;
      final paragraph3 = 'C' * 250;
      final longText = '$paragraph1\n\n$paragraph2\n\n$paragraph3';

      final chunks = service.chunkText(
        longText,
        targetChunkChars: 300,
        overlapChars: 40,
      );

      expect(chunks.length, greaterThanOrEqualTo(2));
      for (int i = 0; i < chunks.length; i++) {
        expect(chunks[i].index, i);
        expect(chunks[i].text.isNotEmpty, isTrue);
      }
    });
  });

  group('DocumentService BM25 Retrieval Tests', () {
    final service = DocumentService.instance;

    final List<DocumentChunk> chunks = [
      const DocumentChunk(
        index: 0,
        text: 'The battery level of the device is currently 85% and charging via USB-C.',
      ),
      const DocumentChunk(
        index: 1,
        text: 'Syncfusion Flutter PDF provides pure Dart extraction of text and images.',
      ),
      const DocumentChunk(
        index: 2,
        text: 'Pocket AI is an offline LLM app running quantized GGUF models on mobile CPU.',
      ),
      const DocumentChunk(
        index: 3,
        text: 'Wi-Fi 6 offers higher bandwidth and lower latency in enterprise networks.',
      ),
    ];

    test('Ranks chunk with matching terms at the top', () {
      final results = service.retrieveRelevantChunks(
        'How does Pocket AI run GGUF models offline?',
        chunks,
        maxChunks: 2,
      );

      expect(results.isNotEmpty, isTrue);
      expect(results.first.index, 2);
      expect(results.first.text, contains('Pocket AI is an offline LLM app'));
    });

    test('Ranks battery info for battery query', () {
      final results = service.retrieveRelevantChunks(
        'What is the current battery status?',
        chunks,
        maxChunks: 1,
      );

      expect(results.length, 1);
      expect(results.first.index, 0);
      expect(results.first.text, contains('battery level'));
    });

    test('Falls back gracefully on empty query', () {
      final results = service.retrieveRelevantChunks('', chunks, maxChunks: 2);
      expect(results.length, 2);
      expect(results[0].index, 0);
      expect(results[1].index, 1);
    });

    test('Returns empty when chunk list is empty', () {
      final results = service.retrieveRelevantChunks('query', []);
      expect(results, isEmpty);
    });
  });

  group('DocumentService Prompt Builder Tests', () {
    final service = DocumentService.instance;

    test('buildRagSystemPrompt includes document metadata and excerpts', () {
      final doc = AttachedDocument(
        id: 'doc-1',
        name: 'quarterly_financials.pdf',
        path: '/docs/quarterly_financials.pdf',
        sizeBytes: 15420,
        fullText: 'Q3 revenue rose by 14% to 2.4 million dollars.',
        chunks: const [
          DocumentChunk(
            index: 0,
            text: 'Q3 revenue rose by 14% to 2.4 million dollars.',
          ),
        ],
      );

      final prompt = service.buildRagSystemPrompt(
        document: doc,
        relevantChunks: doc.chunks,
      );

      expect(prompt, contains('quarterly_financials.pdf'));
      expect(prompt, contains('Use ONLY the facts directly stated in the DOCUMENT CONTEXT'));
      expect(prompt, contains('Q3 revenue rose by 14%'));
      expect(prompt, contains('[Excerpt 1]'));
    });
  });

  group('Document UI Widget Tests', () {
    testWidgets('Attached document chip renders name, size, chunks and handles detach', (tester) async {
      AttachedDocument? currentDoc = const AttachedDocument(
        id: 'doc-1',
        name: 'quarterly_report.pdf',
        path: '/path/quarterly_report.pdf',
        sizeBytes: 2048,
        fullText: 'Report text',
        chunks: [
          DocumentChunk(index: 0, text: 'Report text'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    if (currentDoc != null)
                      Container(
                        margin: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              currentDoc!.extension == 'pdf'
                                  ? Icons.picture_as_pdf_rounded
                                  : Icons.description_rounded,
                            ),
                            Text(currentDoc!.name),
                            Text('${currentDoc!.sizeFormatted} • ${currentDoc!.chunks.length} chunks'),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                setState(() {
                                  currentDoc = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('quarterly_report.pdf'), findsOneWidget);
      expect(find.text('2.0 KB • 1 chunks'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(find.text('quarterly_report.pdf'), findsNothing);
    });
  });
}
