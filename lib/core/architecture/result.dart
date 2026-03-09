/// Represents the result of an operation that can succeed or fail
sealed class Result<T> {
  const Result();

  /// Maps the success value to another type
  Result<R> map<R>(R Function(T) transform) {
    return switch (this) {
      Success(:final value) => Success(transform(value)),
      Failure(:final exception) => Failure(exception),
    };
  }

  /// Maps the failure exception to another type
  Result<T> mapError(dynamic Function(dynamic) transform) {
    return switch (this) {
      Success(:final value) => Success(value),
      Failure(:final exception) => Failure(transform(exception)),
    };
  }

  /// Executes a callback if the result is successful
  void fold({
    required void Function(T) onSuccess,
    required void Function(dynamic) onFailure,
  }) {
    switch (this) {
      case Success(:final value):
        onSuccess(value);
      case Failure(:final exception):
        onFailure(exception);
    }
  }

  /// Returns true if the result is a success
  bool get isSuccess => this is Success<T>;

  /// Returns true if the result is a failure
  bool get isFailure => this is Failure;

  /// Gets the value if successful, or null if failed
  T? getOrNull() {
    return switch (this) {
      Success(:final value) => value,
      Failure() => null,
    };
  }

  /// Gets the exception if failed, or null if successful
  dynamic getErrorOrNull() {
    return switch (this) {
      Success() => null,
      Failure(:final exception) => exception,
    };
  }
}

/// Success result containing the value
class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  String toString() => 'Success($value)';
}

/// Failure result containing the exception
class Failure<T> extends Result<T> {
  final dynamic exception;

  const Failure(this.exception);

  @override
  String toString() => 'Failure($exception)';
}
