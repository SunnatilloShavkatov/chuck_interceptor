import 'dart:io';

import 'package:chuck_interceptor/src/core/chuck_core.dart';
import 'package:chuck_interceptor/src/core/chuck_dio_interceptor.dart';
import 'package:chuck_interceptor/src/core/chuck_generic_adapter.dart';
import 'package:chuck_interceptor/src/core/chuck_http_client_adapter.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_button.dart';
import 'package:flutter/widgets.dart';

export 'package:chuck_interceptor/src/core/chuck_core.dart';
export 'package:chuck_interceptor/src/core/chuck_dio_interceptor.dart';
export 'package:chuck_interceptor/src/core/chuck_generic_adapter.dart';
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
    _httpClientAdapter = ChuckHttpClientAdapter(_chuckCore);
    _genericAdapter = ChuckGenericAdapter(_chuckCore);
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
  late ChuckGenericAdapter _genericAdapter;

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

  /// Client agnostic adapter. Use it to inspect traffic from any http client
  /// Chuck has no built-in integration for (`package:http`, `chopper`,
  /// `retrofit`, a custom client): it only needs plain values, so Chuck does
  /// not depend on those packages.
  ChuckGenericAdapter get genericAdapter => _genericAdapter;

  /// Log a finished request and response in one step. Handy for clients which
  /// only expose the call once it has completed, e.g. `package:http`:
  ///
  /// ```dart
  /// final response = await http.get(url);
  /// chuck.logHttpCall(
  ///   method: response.request!.method,
  ///   uri: response.request!.url,
  ///   statusCode: response.statusCode,
  ///   requestHeaders: response.request?.headers,
  ///   responseHeaders: response.headers,
  ///   responseBody: response.body,
  ///   client: 'http package',
  /// );
  /// ```
  ///
  /// Returns the id of the created call, or `-1` when Chuck is disabled.
  int logHttpCall({
    required String method,
    required Uri uri,
    int? statusCode,
    Map<String, dynamic>? requestHeaders,
    Object? requestBody,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? responseHeaders,
    Object? responseBody,
    Duration? duration,
    Object? error,
    StackTrace? stackTrace,
    String client = 'Custom',
    int? id,
  }) => _genericAdapter.onCall(
    method: method,
    uri: uri,
    statusCode: statusCode,
    requestHeaders: requestHeaders,
    requestBody: requestBody,
    queryParameters: queryParameters,
    responseHeaders: responseHeaders,
    responseBody: responseBody,
    duration: duration,
    error: error,
    stackTrace: stackTrace,
    client: client,
    id: id,
  );

  /// Log a request which has not finished yet and get back its call id. Pass
  /// that id to [logResponse] or [logError] once the request completes. Use it
  /// for streaming clients, where the response arrives later.
  ///
  /// Returns the id of the created call, or `-1` when Chuck is disabled.
  int logRequest({
    required String method,
    required Uri uri,
    Map<String, dynamic>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
    String client = 'Custom',
    int? id,
  }) => _genericAdapter.onRequest(
    method: method,
    uri: uri,
    headers: headers,
    body: body,
    queryParameters: queryParameters,
    client: client,
    id: id,
  );

  /// Attach a response to the call created by [logRequest].
  void logResponse(int callId, {int? statusCode, Map<String, String>? headers, Object? body}) {
    _genericAdapter.onResponse(callId, statusCode: statusCode, headers: headers, body: body);
  }

  /// Attach an error to the call created by [logRequest].
  void logError(int callId, Object error, {StackTrace? stackTrace}) {
    _genericAdapter.onError(callId, error, stackTrace: stackTrace);
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
