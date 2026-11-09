/// Configuration parameters for on-device local LLM execution.
class InferenceConfig {
  /// Number of CPU worker threads used during token generation.
  final int numberOfThreads;

  /// Context window size in tokens allocated in the KV cache.
  final int contextSize;

  /// Generation sampling temperature (0.0 = deterministic/strict, 1.0 = creative).
  final double temperature;

  /// Maximum tokens to generate per response turn.
  final int maxTokens;

  const InferenceConfig({
    this.numberOfThreads = 4,
    this.contextSize = 2048,
    this.temperature = 0.3,
    this.maxTokens = 256,
  });

  static const defaults = InferenceConfig();

  InferenceConfig copyWith({
    int? numberOfThreads,
    int? contextSize,
    double? temperature,
    int? maxTokens,
  }) {
    return InferenceConfig(
      numberOfThreads: numberOfThreads ?? this.numberOfThreads,
      contextSize: contextSize ?? this.contextSize,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
    );
  }

  Map<String, dynamic> toJson() => {
    'numberOfThreads': numberOfThreads,
    'contextSize': contextSize,
    'temperature': temperature,
    'maxTokens': maxTokens,
  };

  factory InferenceConfig.fromJson(Map<String, dynamic> json) => InferenceConfig(
    numberOfThreads: json['numberOfThreads'] as int? ?? 4,
    contextSize: json['contextSize'] as int? ?? 2048,
    temperature: (json['temperature'] as num?)?.toDouble() ?? 0.3,
    maxTokens: json['maxTokens'] as int? ?? 256,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InferenceConfig &&
          runtimeType == other.runtimeType &&
          numberOfThreads == other.numberOfThreads &&
          contextSize == other.contextSize &&
          temperature == other.temperature &&
          maxTokens == other.maxTokens;

  @override
  int get hashCode =>
      numberOfThreads.hashCode ^
      contextSize.hashCode ^
      temperature.hashCode ^
      maxTokens.hashCode;
}
