/// Metadata specification for a GGUF language model.
class ModelSpec {
  /// Unique identifier of the model.
  final String id;

  /// Display name of the model.
  final String name;

  /// Short description explaining capabilities and best use cases.
  final String description;

  /// Category tag (e.g., 'Ultra-Fast', 'Balanced (Default)', 'High Intelligence').
  final String category;

  /// Local GGUF file name stored in application support directory.
  final String fileName;

  /// Direct Hugging Face download URL.
  final String downloadUrl;

  /// Estimated file size in bytes.
  final int sizeBytes;

  /// Optional SHA-256 cryptographic digest for integrity validation.
  final String? sha256;

  /// Minimum recommended device RAM.
  final String recommendedRam;

  const ModelSpec({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.fileName,
    required this.downloadUrl,
    required this.sizeBytes,
    this.sha256,
    required this.recommendedRam,
  });

  /// Factory constructor to deserialize from JSON map.
  factory ModelSpec.fromJson(Map<String, dynamic> json) {
    return ModelSpec(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      fileName: json['fileName'] as String,
      downloadUrl: json['downloadUrl'] as String,
      sizeBytes: json['sizeBytes'] as int,
      sha256: json['sha256'] as String?,
      recommendedRam: json['recommendedRam'] as String,
    );
  }

  /// Converts this specification to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'fileName': fileName,
        'downloadUrl': downloadUrl,
        'sizeBytes': sizeBytes,
        'sha256': sha256,
        'recommendedRam': recommendedRam,
      };

  /// Human-readable file size string (e.g. "634 MB", "1.0 GB").
  String get sizeFormatted {
    final mb = sizeBytes / (1024 * 1024);
    if (mb >= 1000) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
    return '${mb.toStringAsFixed(0)} MB';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelSpec && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
