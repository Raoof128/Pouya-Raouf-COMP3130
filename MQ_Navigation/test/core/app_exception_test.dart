import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/core/error/app_exception.dart';

void main() {
  group('AppException hierarchy', () {
    test('NetworkException stores message', () {
      const e = NetworkException('No connection');
      expect(e.message, 'No connection');
      expect(e.cause, isNull);
      expect(e.toString(), contains('NetworkException'));
    });

    test('AuthException stores message and cause', () {
      final cause = Exception('token expired');
      final e = AuthException('Session expired', cause);
      expect(e.message, 'Session expired');
      expect(e.cause, cause);
    });

    test('ServerException stores status code', () {
      const e = ServerException('Not found', statusCode: 404);
      expect(e.message, 'Not found');
      expect(e.statusCode, 404);
    });

    test('ServerException stores cause', () {
      final cause = Exception('timeout');
      final e = ServerException(
        'Gateway timeout',
        statusCode: 504,
        cause: cause,
      );
      expect(e.cause, cause);
    });

    test('StorageException is an AppException', () {
      const e = StorageException('Write failed');
      expect(e, isA<AppException>());
      expect(e.message, 'Write failed');
    });

    test('UnsupportedException is an AppException', () {
      const e = UnsupportedException('No biometrics');
      expect(e, isA<AppException>());
    });

    test('sealed class prevents instantiation of AppException directly', () {
      // All concrete types should be AppException subtypes
      expect(const NetworkException('x'), isA<AppException>());
      expect(const AuthException('x'), isA<AppException>());
      expect(const ServerException('x'), isA<AppException>());
      expect(const StorageException('x'), isA<AppException>());
      expect(const UnsupportedException('x'), isA<AppException>());
    });
  });
}
