import 'dart:typed_data';

/// Represents a chunk of text extracted from an attached document.
class DocumentChunk {
  final int index;
  final String text;

  const DocumentChunk({
    required this.index,
    required this.text,
  });

  /// Rough estimate of tokens (1 token ~= 4 characters).
  int get tokenEstimate => (text.length / 4).ceil();
}

/// Represents an attached local document (PDF, TXT, or MD) for on-device RAG.
class AttachedDocument {
  final String id;
  final String name;
  final String path;
  final int sizeBytes;
  final String fullText;
  final List<DocumentChunk> chunks;
  final Uint8List? rawBytes;

  const AttachedDocument({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.fullText,
    required this.chunks,
    this.rawBytes,
  });

  /// Returns clean human-readable file size (KB / MB).
  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// File extension in lower case (e.g. 'pdf', 'txt', 'md').
  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot != -1 && dot < name.length - 1) {
      return name.substring(dot + 1).toLowerCase();
    }
    return '';
  }
}
