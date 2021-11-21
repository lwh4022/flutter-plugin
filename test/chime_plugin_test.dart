import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chime_plugin/chime_plugin.dart';

void main() {
  const MethodChannel channel = MethodChannel('chime_plugin');

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
    expect(await ChimePlugin.platformVersion, '42');
  });
}
