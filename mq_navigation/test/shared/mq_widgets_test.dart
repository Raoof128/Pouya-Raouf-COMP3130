import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/app/theme/mq_theme.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';
import 'package:mq_navigation/shared/widgets/mq_card.dart';
import 'package:mq_navigation/shared/widgets/mq_input.dart';

/// Wraps a widget with MaterialApp for testing.
Widget testApp(Widget child) {
  return MaterialApp(
    theme: MqTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  group('MqButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        testApp(MqButton(label: 'Sign In', onPressed: () {})),
      );
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        testApp(MqButton(label: 'Tap Me', onPressed: () => tapped = true)),
      );
      await tester.tap(find.text('Tap Me'));
      expect(tapped, isTrue);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        testApp(MqButton(label: 'Save', onPressed: () {}, isLoading: true)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('disables tap when isLoading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        testApp(
          MqButton(
            label: 'Save',
            onPressed: () => tapped = true,
            isLoading: true,
          ),
        ),
      );
      await tester.tap(find.byType(FilledButton));
      expect(tapped, isFalse);
    });

    testWidgets('renders outlined variant', (tester) async {
      await tester.pumpWidget(
        testApp(
          MqButton(
            label: 'Cancel',
            onPressed: () {},
            variant: MqButtonVariant.outlined,
          ),
        ),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('renders text variant', (tester) async {
      await tester.pumpWidget(
        testApp(
          MqButton(
            label: 'Skip',
            onPressed: () {},
            variant: MqButtonVariant.text,
          ),
        ),
      );
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        testApp(MqButton(label: 'Add', onPressed: () {}, icon: Icons.add)),
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('meets minimum tap target height', (tester) async {
      await tester.pumpWidget(
        testApp(MqButton(label: 'Test', onPressed: () {})),
      );
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, greaterThanOrEqualTo(48));
    });
  });

  group('MqCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        testApp(const MqCard(child: Text('Card Content'))),
      );
      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('wraps in Card widget', (tester) async {
      await tester.pumpWidget(testApp(const MqCard(child: Text('Hello'))));
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders InkWell when onTap is provided', (tester) async {
      await tester.pumpWidget(
        testApp(MqCard(child: const Text('Tap'), onTap: () {})),
      );
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('does not render InkWell when onTap is null', (tester) async {
      await tester.pumpWidget(testApp(const MqCard(child: Text('No Tap'))));
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        testApp(
          MqCard(child: const Text('Tap Me'), onTap: () => tapped = true),
        ),
      );
      await tester.tap(find.text('Tap Me'));
      expect(tapped, isTrue);
    });
  });

  group('MqInput', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(testApp(const MqInput(label: 'Email')));
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('renders prefix icon', (tester) async {
      await tester.pumpWidget(
        testApp(const MqInput(label: 'Email', prefixIcon: Icons.email)),
      );
      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('calls onChanged when text entered', (tester) async {
      String? value;
      await tester.pumpWidget(
        testApp(MqInput(label: 'Name', onChanged: (v) => value = v)),
      );
      await tester.enterText(find.byType(TextFormField), 'Raouf');
      expect(value, 'Raouf');
    });

    testWidgets('obscures text when obscureText is true', (tester) async {
      await tester.pumpWidget(
        testApp(const MqInput(label: 'Password', obscureText: true)),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
    });

    testWidgets('is disabled when enabled is false', (tester) async {
      await tester.pumpWidget(
        testApp(const MqInput(label: 'Disabled', enabled: false)),
      );
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.enabled, isFalse);
    });
  });
}
