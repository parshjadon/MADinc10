import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signup_app/main.dart';
import 'package:signup_app/signup_tip.dart';

Future<void> submit(WidgetTester tester) async {
  final button = find.byKey(const Key('signup'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester, String key, String value) async {
  await tester.enterText(find.byKey(Key(key)), value);
}

void main() {
  test(
    'fixed category is deterministic and every bundled tip meets length limit',
    () {
      const source = LocalTipSource();
      expect(source.select(), source.select());
      expect(source.select().length, inInclusiveRange(1, 240));
      for (final tip in LocalTipSource.tips[LocalTipSource.category]!) {
        expect(tip.trim().length, inInclusiveRange(1, 240));
      }
      for (final scenario in [
        TipScenario.localError,
        TipScenario.empty,
        TipScenario.missing,
      ]) {
        expect(
          () => source.select(scenario: scenario),
          throwsA(isA<TipFailure>()),
        );
      }
    },
  );

  testWidgets('required fields and invalid input block signup', (tester) async {
    await tester.pumpWidget(const MyApp());
    await submit(tester);
    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter a password'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
    await fill(tester, 'name', '   ');
    await fill(tester, 'email', 'hiker@');
    await fill(tester, 'password', '12345');
    await fill(tester, 'confirmation', '12345');
    await submit(tester);
    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Please enter a valid email'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    expect(find.byType(WelcomePage), findsNothing);
  });

  testWidgets('Task C blocks mismatch then personalizes successful signup', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await fill(tester, 'name', '  Alex Trail  ');
    await fill(tester, 'email', 'alex@example.com');
    await fill(tester, 'password', 'abcdef');
    await fill(tester, 'confirmation', 'ABCDEF');
    await submit(tester);
    expect(find.text('Passwords must match exactly'), findsOneWidget);
    expect(find.byType(WelcomePage), findsNothing);
    await fill(tester, 'confirmation', 'abcdef');
    await submit(tester);
    expect(find.text('Welcome, Alex Trail!'), findsOneWidget);
    expect(
      find.text('Demo signup complete — your form passed validation!'),
      findsOneWidget,
    );
    await tester.tap(find.text('Back to signup'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('password')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('tip loads without approving an invalid form', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.byKey(const Key('get-tip')));
    await tester.tap(find.byKey(const Key('get-tip')));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byKey(const Key('get-tip'))).onPressed,
      isNull,
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('tip-result')), findsOneWidget);
    expect(find.text('Preset demo tip—not live AI.'), findsOneWidget);
    await submit(tester);
    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.byType(WelcomePage), findsNothing);
  });

  for (final label in [
    'Simulated error',
    'Empty tip list',
    'Missing category data',
  ]) {
    testWidgets('$label recovers through Retry', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: SignupTipCard())),
        ),
      );
      await tester.tap(find.byType(DropdownButtonFormField<TipScenario>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('get-tip')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.byKey(const Key('tip-error')), findsOneWidget);
      expect(find.byKey(const Key('tip-result')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('retry')));
      await tester.tap(find.byKey(const Key('retry')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.byKey(const Key('tip-error')), findsNothing);
      expect(find.text(const LocalTipSource().select()), findsOneWidget);
    });
  }

  testWidgets('disposing while loading is safe', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SignupTipCard())),
    );
    await tester.tap(find.byKey(const Key('get-tip')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
