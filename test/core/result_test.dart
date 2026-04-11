import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/core/utils/result.dart';

void main() {
  group('Result', () {
    test('Success holds data', () {
      const result = Success(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.data, 42);
    });

    test('Success with null data', () {
      const result = Success<String?>(null);
      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    test('Failure holds message', () {
      const result = Failure<int>('Something went wrong');
      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.message, 'Something went wrong');
    });

    test('Failure holds cause', () {
      final cause = Exception('root cause');
      final result = Failure<int>('Failed', cause);
      expect(result.cause, cause);
    });

    test('can be used in type switch', () {
      const Result<int> result = Success(10);
      final value = switch (result) {
        Success<int>(:final data) => data * 2,
        Failure<int>() => -1,
      };
      expect(value, 20);
    });

    test('failure branch in type switch', () {
      const Result<int> result = Failure('error');
      final value = switch (result) {
        Success<int>(:final data) => data,
        Failure<int>(:final message) => message.length,
      };
      expect(value, 5);
    });
  });
}
