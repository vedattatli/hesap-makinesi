/// Controls graph sampling density and discontinuity heuristics.
class GraphSamplingOptions {
  const GraphSamplingOptions({
    this.initialSamples = 512,
    this.maxSamples = 4096,
    this.adaptiveDepth = 6,
    this.discontinuityThreshold = 6.0,
    this.minStep = 1e-4,
    this.maxEvaluationErrors = 512,
    this.enableAdaptiveSampling = true,
    this.enableDiscontinuityDetection = true,
  }) : assert(initialSamples >= 8, 'initialSamples must be >= 8'),
       assert(
         maxSamples >= initialSamples,
         'maxSamples must be >= initialSamples',
       ),
       assert(adaptiveDepth >= 0, 'adaptiveDepth must be non-negative'),
       assert(
         discontinuityThreshold > 0,
         'discontinuityThreshold must be positive',
       ),
       assert(minStep > 0, 'minStep must be positive'),
       assert(
         maxEvaluationErrors >= 0,
         'maxEvaluationErrors must be non-negative',
       );

  final int initialSamples;
  final int maxSamples;
  final int adaptiveDepth;
  final double discontinuityThreshold;
  final double minStep;
  final int maxEvaluationErrors;
  final bool enableAdaptiveSampling;
  final bool enableDiscontinuityDetection;

  static const int hardMaxInitialSamples = 8192;
  static const int hardMaxSamples = 8192;
  static const int hardMaxSeries = 8;
  static const int hardMaxTotalPoints = 50000;

  String get cacheKey =>
      '$initialSamples:$maxSamples:$adaptiveDepth:'
      '$discontinuityThreshold:$minStep:$maxEvaluationErrors:'
      '$enableAdaptiveSampling:$enableDiscontinuityDetection';
}
