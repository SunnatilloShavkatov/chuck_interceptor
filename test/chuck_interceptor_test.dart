// import 'package:flutter_test/flutter_test.dart';
// import 'package:chuck_interceptor/chuck_interceptor.dart';
// import 'package:chuck_interceptor/chuck_interceptor_platform_interface.dart';
// import 'package:chuck_interceptor/chuck_interceptor_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
//
// class MockChuckInterceptorPlatform
//     with MockPlatformInterfaceMixin
//     implements ChuckInterceptorPlatform {
//
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }
//
// void main() {
//   final ChuckInterceptorPlatform initialPlatform = ChuckInterceptorPlatform.instance;
//
//   test('$MethodChannelChuckInterceptor is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelChuckInterceptor>());
//   });
//
//   test('getPlatformVersion', () async {
//     ChuckInterceptor chuckInterceptorPlugin = ChuckInterceptor();
//     MockChuckInterceptorPlatform fakePlatform = MockChuckInterceptorPlatform();
//     ChuckInterceptorPlatform.instance = fakePlatform;
//
//     expect(await chuckInterceptorPlugin.getPlatformVersion(), '42');
//   });
// }
