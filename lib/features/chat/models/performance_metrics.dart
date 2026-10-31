class PerformanceMetrics {
  final int modelLoadTimeMs;

  const PerformanceMetrics({
    this.modelLoadTimeMs = 0,
  });

  double get modelLoadTimeSeconds =>
      modelLoadTimeMs / 1000.0;
}