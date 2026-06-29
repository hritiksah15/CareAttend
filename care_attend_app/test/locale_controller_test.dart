import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:care_attend_app/state/locale_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/shared_preferences');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    LocaleController.instance.locale.value = const Locale('en');
  });

  test('LocaleController tolerates unavailable preference storage', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw MissingPluginException(
        'No implementation found for method ${call.method} on channel $channel',
      );
    });

    await expectLater(LocaleController.instance.load(), completes);
    await expectLater(LocaleController.instance.set('cy'), completes);

    expect(LocaleController.instance.locale.value, const Locale('cy'));
  });
}
