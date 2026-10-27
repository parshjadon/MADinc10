// Run with: flutter test tool/evidence_test.dart --update-goldens
// These are actual Flutter widget renders, not device screenshots.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signup_app/main.dart';
import 'package:signup_app/signup_tip.dart';

void main() {
  testWidgets('capture reproducible implementation evidence', (tester) async {
    // FLUTTER_ROOT is supplied by flutter test; use the SDK's own fonts.
    final sdk = Platform.environment['FLUTTER_ROOT']!;
    for (final font in {
      'Roboto': 'roboto-regular.ttf',
      'MaterialIcons': 'materialicons-regular.otf',
    }.entries) {
      final loader = FontLoader(font.key);
      loader.addFont(
        Future.value(
          ByteData.sublistView(
            File('$sdk/bin/cache/artifacts/material_fonts/${font.value}')
                .readAsBytesSync(),
          ),
        ),
      );
      await loader.load();
    }
    tester.view.physicalSize = const Size(440, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    Future<void> capture(String name) => expectLater(
      find.byType(MyApp),
      matchesGoldenFile('../evidence/$name.png'),
    );
    Future<void> tapKey(String key) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.tap(find.byKey(Key(key)));
    }

    await capture('01-signup');
    await tapKey('signup');
    await tester.pumpAndSettle();
    await capture('02-required-validation');
    // Fresh screen for isolated local tip evidence.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const MyApp());
    await tapKey('get-tip');
    await tester.pump(const Duration(milliseconds: 100));
    await capture('03-tip-loading');
    await tester.pumpAndSettle();
    await capture('04-tip-success');
    await tester.ensureVisible(
      find.byType(DropdownButtonFormField<TipScenario>),
    );
    await tester.tap(find.byType(DropdownButtonFormField<TipScenario>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Empty tip list').last);
    await tester.pumpAndSettle();
    await tapKey('get-tip');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('retry')));
    await capture('05-empty-tip-error');
    await tapKey('retry');
    await tester.pumpAndSettle();
    await capture('06-tip-retry-success');
    for (final entry in {
      'name': 'Alex Trail',
      'email': 'alex@example.com',
      'password': 'abcdef',
      'confirmation': 'ABCDEF',
    }.entries) {
      await tester.enterText(find.byKey(Key(entry.key)), entry.value);
    }
    await tapKey('signup');
    await tester.pumpAndSettle();
    await capture('07-password-mismatch');
    await tester.enterText(find.byKey(const Key('confirmation')), 'abcdef');
    await tapKey('signup');
    await tester.pumpAndSettle();
    await capture('08-personalized-success');
  });
}
