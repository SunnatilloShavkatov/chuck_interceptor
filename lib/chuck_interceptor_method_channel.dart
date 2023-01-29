import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'chuck_interceptor_platform_interface.dart';

/// An implementation of [ChuckInterceptorPlatform] that uses method channels.
class MethodChannelChuckInterceptor extends ChuckInterceptorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('chuck_interceptor');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
