import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'chuck_interceptor_method_channel.dart';

abstract class ChuckInterceptorPlatform extends PlatformInterface {
  /// Constructs a ChuckInterceptorPlatform.
  ChuckInterceptorPlatform() : super(token: _token);

  static final Object _token = Object();

  static ChuckInterceptorPlatform _instance = MethodChannelChuckInterceptor();

  /// The default instance of [ChuckInterceptorPlatform] to use.
  ///
  /// Defaults to [MethodChannelChuckInterceptor].
  static ChuckInterceptorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ChuckInterceptorPlatform] when
  /// they register themselves.
  static set instance(ChuckInterceptorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
