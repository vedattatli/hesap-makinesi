/// Lightweight, pure-Dart computation task primitives used by heavy calculator
/// surfaces to model cancellation and timing without adding telemetry.
class ComputationCancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw const ComputationCancelledException();
    }
  }
}

class ComputationCancelledException implements Exception {
  const ComputationCancelledException();

  @override
  String toString() => 'Computation was cancelled.';
}

enum ComputationTaskStatus { completed, cancelled, failed }

class ComputationTaskResult<T> {
  const ComputationTaskResult({
    required this.label,
    required this.status,
    required this.elapsed,
    this.value,
    this.error,
  });

  final String label;
  final ComputationTaskStatus status;
  final Duration elapsed;
  final T? value;
  final Object? error;

  bool get isCompleted => status == ComputationTaskStatus.completed;

  bool get isCancelled => status == ComputationTaskStatus.cancelled;
}

class ComputationTaskRunner {
  const ComputationTaskRunner();

  ComputationTaskResult<T> runSync<T>(
    String label,
    T Function(ComputationCancellationToken token) body, {
    ComputationCancellationToken? token,
  }) {
    final cancellationToken = token ?? ComputationCancellationToken();
    final stopwatch = Stopwatch()..start();
    try {
      cancellationToken.throwIfCancelled();
      final value = body(cancellationToken);
      cancellationToken.throwIfCancelled();
      stopwatch.stop();
      return ComputationTaskResult<T>(
        label: label,
        status: ComputationTaskStatus.completed,
        elapsed: stopwatch.elapsed,
        value: value,
      );
    } on ComputationCancelledException catch (error) {
      stopwatch.stop();
      return ComputationTaskResult<T>(
        label: label,
        status: ComputationTaskStatus.cancelled,
        elapsed: stopwatch.elapsed,
        error: error,
      );
    } catch (error) {
      stopwatch.stop();
      return ComputationTaskResult<T>(
        label: label,
        status: ComputationTaskStatus.failed,
        elapsed: stopwatch.elapsed,
        error: error,
      );
    }
  }
}
