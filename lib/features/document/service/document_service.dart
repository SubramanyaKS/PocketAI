import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/attached_document.dart';

/// Service responsible for local offline document ingestion, text extraction,
/// chunking, and BM25-based semantic relevance retrieval.
class DocumentService {
  DocumentService._();

  static final DocumentService instance = DocumentService._();

  /// Prompts the user to pick a local PDF, TXT, or Markdown document.
  Future<AttachedDocument?> pickDocument() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md'],
      );

      if (files.isEmpty) {
        return null;
      }

      final file = files.first;
      final name = file.name;
      final path = file.path ?? '';

      Uint8List? bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        if (path.isNotEmpty) {
          final ioFile = File(path);
          if (await ioFile.exists()) {
            bytes = await ioFile.readAsBytes();
          }
        }
      }

      final size = (await file.length()) ?? (bytes?.length ?? 0);

      if (bytes == null || bytes.isEmpty) {
        throw StateError('Unable to read bytes from selected file: $name');
      }

      final extractedText = extractText(name: name, bytes: bytes);
      if (extractedText.trim().isEmpty) {
        throw StateError(
          'No readable text could be extracted from $name. (Scanned or image-only PDFs are not supported).',
        );
      }

      final chunks = chunkText(extractedText);

      return AttachedDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        path: path,
        sizeBytes: size,
        fullText: extractedText,
        chunks: chunks,
        rawBytes: bytes,
      );
    } catch (e) {
      debugPrint('[DOCUMENT] Error picking or parsing document: $e');
      rethrow;
    }
  }

  /// Extracts plain text from raw document bytes based on file extension.
  String extractText({
    required String name,
    required Uint8List bytes,
  }) {
    final lower = name.toLowerCase();

    if (lower.endsWith('.pdf')) {
      final document = PdfDocument(inputBytes: bytes);
      try {
        final extractor = PdfTextExtractor(document);
        final text = extractor.extractText();
        return text;
      } finally {
        document.dispose();
      }
    }

    // Default for .txt, .md, and other plain text formats
    return utf8.decode(bytes, allowMalformed: true);
  }

  /// Splits document text into manageable semantic chunks with overlap.
  List<DocumentChunk> chunkText(
    String fullText, {
    int targetChunkChars = 600,
    int overlapChars = 80,
  }) {
    final cleanText = fullText.replaceAll('\r\n', '\n').trim();
    if (cleanText.isEmpty) return [];

    // If the text is short enough, return as a single chunk
    if (cleanText.length <= targetChunkChars) {
      return [DocumentChunk(index: 0, text: cleanText)];
    }

    final chunks = <DocumentChunk>[];
    final paragraphs = cleanText.split(RegExp(r'\n{2,}'));

    final buffer = StringBuffer();
    var chunkIndex = 0;

    for (final para in paragraphs) {
      final trimmedPara = para.trim();
      if (trimmedPara.isEmpty) continue;

      if (buffer.length + trimmedPara.length > targetChunkChars && buffer.isNotEmpty) {
        final chunkText = buffer.toString().trim();
        chunks.add(DocumentChunk(index: chunkIndex++, text: chunkText));

        // Create overlap from the end of the previous chunk
        buffer.clear();
        if (chunkText.length > overlapChars) {
          final overlap = chunkText.substring(chunkText.length - overlapChars);
          buffer.write(overlap);
          buffer.write('\n');
        }
      }

      // If a single paragraph itself exceeds targetChunkChars, split it into sentences
      if (trimmedPara.length > targetChunkChars) {
        final sentences = trimmedPara.split(RegExp(r'(?<=[.?!])\s+'));
        for (final sentence in sentences) {
          if (buffer.length + sentence.length > targetChunkChars && buffer.isNotEmpty) {
            chunks.add(DocumentChunk(index: chunkIndex++, text: buffer.toString().trim()));
            buffer.clear();
          }
          buffer.write(sentence);
          buffer.write(' ');
        }
      } else {
        buffer.write(trimmedPara);
        buffer.write('\n\n');
      }
    }

    if (buffer.isNotEmpty && buffer.toString().trim().isNotEmpty) {
      chunks.add(DocumentChunk(index: chunkIndex++, text: buffer.toString().trim()));
    }

    return chunks;
  }

  /// Common English stop words filtered out during BM25/keyword retrieval
  static const Set<String> _stopWords = {
    'a', 'about', 'above', 'after', 'again', 'against', 'all', 'am', 'an',
    'and', 'any', 'are', 'as', 'at', 'be', 'because', 'been', 'before', 'being',
    'below', 'between', 'both', 'but', 'by', 'can', 'could', 'did', 'do',
    'does', 'doing', 'down', 'during', 'each', 'few', 'for', 'from', 'further',
    'had', 'has', 'have', 'having', 'he', 'her', 'here', 'hers', 'herself',
    'him', 'himself', 'his', 'how', 'i', 'if', 'in', 'into', 'is', 'it', 'its',
    'itself', 'just', 'me', 'more', 'most', 'my', 'myself', 'no', 'nor', 'not',
    'of', 'off', 'on', 'once', 'only', 'or', 'other', 'ought', 'our', 'ours',
    'ourselves', 'out', 'over', 'own', 'same', 'she', 'should', 'so', 'some',
    'such', 'than', 'that', 'the', 'their', 'theirs', 'them', 'themselves',
    'then', 'there', 'these', 'they', 'this', 'those', 'through', 'to', 'too',
    'under', 'until', 'up', 'very', 'was', 'we', 'were', 'what', 'when',
    'where', 'which', 'while', 'who', 'whom', 'why', 'with', 'would', 'you',
    'your', 'yours', 'yourself', 'yourselves'
  };

  /// Tokenizes a string into lower-case alphanumeric keyword tokens.
  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1 && !_stopWords.contains(t))
        .toList();
  }

  /// High-speed on-device BM25 / TF-IDF relevance retriever.
  /// Ranks chunks against the user's query and returns the top [maxChunks].
  List<DocumentChunk> retrieveRelevantChunks(
    String query,
    List<DocumentChunk> chunks, {
    int maxChunks = 3,
  }) {
    if (chunks.isEmpty) return [];
    if (chunks.length <= maxChunks) return chunks;

    final queryTokens = _tokenize(query);

    // If query has no substantive keywords (e.g. "summarize"), return initial chunks
    if (queryTokens.isEmpty) {
      return chunks.take(maxChunks).toList();
    }

    final totalChunks = chunks.length;
    final chunkTokenMaps = <Map<String, int>>[];
    final docFrequency = <String, int>{};

    for (final chunk in chunks) {
      final tokens = _tokenize(chunk.text);
      final freq = <String, int>{};
      for (final t in tokens) {
        freq[t] = (freq[t] ?? 0) + 1;
      }
      chunkTokenMaps.add(freq);

      for (final t in freq.keys) {
        docFrequency[t] = (docFrequency[t] ?? 0) + 1;
      }
    }

    // Average chunk length in tokens
    double totalTokens = 0;
    for (final map in chunkTokenMaps) {
      totalTokens += map.values.fold(0, (a, b) => a + b);
    }
    final avgDocLen = totalTokens / totalChunks;

    // BM25 parameters
    const k1 = 1.2;
    const b = 0.75;

    final scoredChunks = <MapEntry<DocumentChunk, double>>[];

    for (var i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final freqMap = chunkTokenMaps[i];
      final docLen = freqMap.values.fold(0, (a, b) => a + b);

      double score = 0.0;

      for (final qToken in queryTokens) {
        final tf = freqMap[qToken] ?? 0;
        if (tf == 0) continue;

        final df = docFrequency[qToken] ?? 1;
        // Inverse Document Frequency (IDF)
        final idf = math.log(1 + (totalChunks - df + 0.5) / (df + 0.5));

        // BM25 Term Weight
        final termScore = idf * (tf * (k1 + 1)) / (tf + k1 * (1 - b + b * (docLen / avgDocLen)));
        score += termScore;
      }

      // Bonus for exact query phrase match
      if (chunk.text.toLowerCase().contains(query.trim().toLowerCase())) {
        score += 3.0;
      }

      scoredChunks.add(MapEntry(chunk, score));
    }

    // Sort by descending score
    scoredChunks.sort((a, b) => b.value.compareTo(a.value));

    // If no chunk scored above 0, return the first few chunks (lead paragraphs)
    if (scoredChunks.first.value <= 0.0) {
      return chunks.take(maxChunks).toList();
    }

    return scoredChunks.take(maxChunks).map((e) => e.key).toList();
  }

  /// Builds a grounded RAG prompt injecting the retrieved document context.
  String buildRagSystemPrompt({
    required AttachedDocument document,
    required List<DocumentChunk> relevantChunks,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('You are Pocket AI, an intelligent offline assistant analyzing the attached document: "${document.name}".');
    buffer.writeln('Strict Rules:');
    buffer.writeln('1. Use ONLY the facts directly stated in the DOCUMENT CONTEXT below to answer the user question.');
    buffer.writeln('2. If the answer cannot be found in the provided context, state clearly: "I cannot find that information in the attached document."');
    buffer.writeln('3. Cite relevant sections or facts accurately. Do not invent dates, names, or details.');
    buffer.writeln('4. Keep your answer concise and clearly formatted with bullet points or bold text where appropriate.');
    buffer.writeln();
    buffer.writeln('=== DOCUMENT CONTEXT ===');
    for (var i = 0; i < relevantChunks.length; i++) {
      buffer.writeln('[Excerpt ${i + 1}]');
      buffer.writeln(relevantChunks[i].text.trim());
      buffer.writeln();
    }
    buffer.writeln('========================');

    return buffer.toString();
  }
}
