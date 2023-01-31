import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chuck_interceptor/chuck_interceptor_method_channel.dart';

void main() {
  MethodChannelChuckInterceptor platform = MethodChannelChuckInterceptor();
  const MethodChannel channel = MethodChannel('chuck_interceptor');

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
    expect(await platform.getPlatformVersion(), '42');
  });
}
