import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokwire_plugin/rokwire_plugin.dart';

void main() {
  const MethodChannel channel = MethodChannel('edu.illinois.rokwire/plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await RokwirePlugin.platformVersion, '42');
  });
}
