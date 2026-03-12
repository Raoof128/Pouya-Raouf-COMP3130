import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/core/error/error_boundary.dart';

void main() {
  testWidgets('ErrorBoundary transparently renders its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ErrorBoundary(
          child: Text('child content', textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(find.text('child content'), findsOneWidget);
  });

  testWidgets('buildFrameworkErrorFallback renders without MaterialApp', (
    tester,
  ) async {
    await tester.pumpWidget(buildFrameworkErrorFallback(StateError('boom')));

    expect(find.text('Application error'), findsOneWidget);
    expect(
      find.text('Something went wrong while building the UI.'),
      findsOneWidget,
    );
    expect(find.textContaining('boom'), findsOneWidget);
  });

  test('installErrorHandlers configures global logging handlers', () {
    final previousHandler = FlutterError.onError;
    final previousPlatformHandler = PlatformDispatcher.instance.onError;

    try {
      installErrorHandlers();

      expect(FlutterError.onError, isNotNull);
      expect(PlatformDispatcher.instance.onError, isNotNull);
    } finally {
      FlutterError.onError = previousHandler;
      PlatformDispatcher.instance.onError = previousPlatformHandler;
    }
  });
}
