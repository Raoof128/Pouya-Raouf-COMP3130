/// A simple Result type for operations that can fail without throwing.
///
/// Use exhaustive `switch` or pattern matching to handle both cases:
/// ```dart
/// final result = await fetchUser();
/// switch (result) {
///   case Success(:final data):  print(data);
///   case Failure(:final message): print(message);
/// }
/// ```
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends Result<T> {
  const Failure(this.message, [this.cause]);
  final String message;
  final Object? cause;
}
