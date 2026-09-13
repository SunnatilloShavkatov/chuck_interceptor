import 'dart:io';

import 'package:chuck_interceptor/src/core/chuck_core.dart';
import 'package:chuck_interceptor/src/core/chuck_dio_interceptor.dart';
import 'package:chuck_interceptor/src/core/chuck_http_adapter.dart';
import 'package:chuck_interceptor/src/core/chuck_http_client_adapter.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_button.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

export 'package:chuck_interceptor/src/core/chuck_core.dart';
export 'package:chuck_interceptor/src/core/chuck_dio_interceptor.dart';
export 'package:chuck_interceptor/src/core/chuck_http_client_adapter.dart';
export 'package:chuck_interceptor/src/core/chuck_http_client_extensions.dart';
export 'package:chuck_interceptor/src/model/chuck_http_call.dart';
export 'package:chuck_interceptor/src/model/chuck_http_request.dart';
export 'package:chuck_interceptor/src/model/chuck_http_response.dart';
export 'package:chuck_interceptor/src/theme/chuck_theme.dart';
export 'package:chuck_interceptor/src/theme/chuck_theme_data.dart';
export 'package:chuck_interceptor/src/ui/widget/chuck_button.dart';

final class Chuck {
  /// Creates Chuck instance.
  new({
    GlobalKey<NavigatorState>? navigatorKey,
    this.enabled = true,
    this.maxCallsCount = 1000,
    this.maxBodySize = 1024 * 1024,
    this.showInspectorOnShake = false,
  }) {
    _navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>();
    _chuckCore = ChuckCore(
      _navigatorKey,
      enabled: enabled,
      maxBodySize: maxBodySize,
      maxCallsCount: maxCallsCount,
      showInspectorOnShake: showInspectorOnShake,
    );
    _httpAdapter = ChuckHttpAdapter(_chuckCore);
    _httpClientAdapter = ChuckHttpClientAdapter(_chuckCore);
  }

  /// Whether Chuck is enabled. When disabled, interceptors pass requests through with zero overhead.
  final bool enabled;

  /// Maximum size of request/response body in bytes to store in memory (default: 256 KB)
  final int maxBodySize;

  /// Should inspector be opened on device shake (works only with physical
  /// with sensors)
  final bool showInspectorOnShake;

  ///Max number of calls that are stored in memory. When count is reached, FIFO
  ///method queue will be used to remove elements.
  final int maxCallsCount;

  GlobalKey<NavigatorState>? _navigatorKey;
  late ChuckCore _chuckCore;
  late ChuckHttpClientAdapter _httpClientAdapter;
  late ChuckHttpAdapter _httpAdapter;

  /// Set custom navigation key. This will help if there's route library.
  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _chuckCore.navigatorKey = navigatorKey;
  }

  /// Get currently used navigation key
  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  /// Core instance which stores intercepted calls. Useful when building custom
  /// UI on top of Chuck, e.g. your own inspector entry point.
  ChuckCore get core => _chuckCore;

  /// Reactive stream of all intercepted http calls.
  Stream<List<ChuckHttpCall>> get callsStream => _chuckCore.callsStream;

  /// Builder which renders floating [ChuckButton] above the application. Pass
  /// it directly to `MaterialApp.builder` to get a button which opens the
  /// inspector:
  ///
  /// ```dart
  /// MaterialApp(
  ///   navigatorKey: chuck.navigatorKey,
  ///   builder: chuck.builder,
  /// );
  /// ```
  Widget builder(BuildContext context, Widget? child) => ChuckButton(chuckCore: _chuckCore, child: child);

  /// Get Dio interceptor which should be applied to Dio instance.
  ChuckDioInterceptor get dioInterceptor => ChuckDioInterceptor(_chuckCore);

  /// Handle request from HttpClient
  void onHttpClientRequest(HttpClientRequest request, {Object? body}) {
    _httpClientAdapter.onRequest(request, body: body);
  }

  /// Handle response from HttpClient
  Future<void> onHttpClientResponse(HttpClientResponse response, HttpClientRequest request, {Object? body}) async {
    await _httpClientAdapter.onResponse(response, request, body: body);
  }

  /// Handle both request and response from http package
  void onHttpResponse(http.Response response, {Object? body}) {
    _httpAdapter.onResponse(response, body: body);
  }

  /// Opens Http calls inspector. This will navigate user to the new fullscreen
  /// page where all listened http calls can be viewed.
  void showInspector() => _chuckCore.navigateToCallListScreen();

  /// Handle generic http call. Can be used to any http client.
  void addHttpCall(ChuckHttpCall chuckHttpCall) {
    assert(chuckHttpCall.request != null, "Http call request can't be null");
    assert(chuckHttpCall.response != null, "Http call response can't be null");
    _chuckCore.addCall(chuckHttpCall);
  }

  /// Dispose of resources used by Chuck.
  /// Call this method when Chuck is no longer needed to prevent memory leaks.
  void dispose() {
    _chuckCore.dispose();
  }
}
