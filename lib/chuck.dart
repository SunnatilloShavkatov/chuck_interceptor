import 'dart:async';
import 'dart:io';
import 'package:chuck_interceptor/core/chuck_generic_adapter.dart';
import 'package:chuck_interceptor/model/chuck_http_call.dart';

import 'package:chuck_interceptor/core/chuck_core.dart';
import 'package:chuck_interceptor/core/chuck_dio_interceptor.dart';
import 'package:chuck_interceptor/core/chuck_http_client_adapter.dart';
import 'package:chuck_interceptor/ui/widget/chuck_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

class Chuck {
  /// Should inspector be opened on device shake (works only with physical
  /// with sensors)
  final bool showInspectorOnShake;

  /// Should inspector use dark theme
  final bool darkTheme;

  ///Max number of calls that are stored in memory. When count is reached, FIFO
  ///method queue will be used to remove elements.
  final int maxCallsCount;

  ///Initial max number of calls persisted in [cacheBox], used until the user
  ///picks a size in the inspector. Zero, the default, keeps the cache off.
  final int maxCacheCount;

  ///Directionality of app. Directionality of the app will be used if set to null.
  final TextDirection? directionality;

  ///App name written in the shared/saved log header. Omitted when null.
  final String? appName;

  ///App version written in the shared/saved log header. Omitted when null.
  final String? appVersion;

  ///Called with the call log when the share button is pressed. When null, the
  ///log is copied to the clipboard instead.
  final FutureOr<void> Function(String text)? onShare;

  GlobalKey<NavigatorState>? _navigatorKey;
  final Box<dynamic>? cacheBox;
  late ChuckCore _chuckCore;
  late ChuckHttpClientAdapter _httpClientAdapter;
  late ChuckGenericAdapter _genericAdapter;

  /// Creates Chuck instance.
  Chuck({
    GlobalKey<NavigatorState>? navigatorKey,
    this.cacheBox,
    this.showInspectorOnShake = false,
    this.darkTheme = false,
    this.maxCallsCount = 1000,
    this.maxCacheCount = 0,
    this.directionality,
    this.appName,
    this.appVersion,
    this.onShare,
  }) {
    _navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>();
    _chuckCore = ChuckCore(
      _navigatorKey,
      onShare: onShare,
      appName: appName,
      cacheBox: cacheBox,
      darkTheme: darkTheme,
      appVersion: appVersion,
      maxCallsCount: maxCallsCount,
      maxCacheCount: maxCacheCount,
      directionality: directionality,
      showInspectorOnShake: showInspectorOnShake,
    );
    _httpClientAdapter = ChuckHttpClientAdapter(_chuckCore);
    _genericAdapter = ChuckGenericAdapter(_chuckCore);
  }

  /// Set custom navigation key. This will help if there's route library.
  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _chuckCore.navigatorKey = navigatorKey;
  }

  /// Get currently used navigation key
  GlobalKey<NavigatorState>? getNavigatorKey() {
    return _navigatorKey;
  }

  /// Builder which renders a floating [ChuckButton] above the application.
  /// Pass it directly to `MaterialApp.builder`:
  ///
  /// ```dart
  /// MaterialApp(
  ///   navigatorKey: chuck.getNavigatorKey(),
  ///   builder: chuck.builder,
  ///   home: const HomeScreen(),
  /// );
  /// ```
  Widget builder(BuildContext context, Widget? child) => ChuckButton(chuckCore: _chuckCore, child: child);

  /// Get Dio interceptor which should be applied to Dio instance.
  ChuckDioInterceptor get dioInterceptor => ChuckDioInterceptor(_chuckCore);

  /// Handle request from HttpClient
  void onHttpClientRequest(HttpClientRequest request, {dynamic body}) {
    _httpClientAdapter.onRequest(request, body: body);
  }

  /// Handle response from HttpClient
  void onHttpClientResponse(HttpClientResponse response, HttpClientRequest request, {dynamic body}) {
    _httpClientAdapter.onResponse(response, request, body: body);
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
  /// Returns the id of the created call.
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
    String client = "Custom",
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
  int logRequest({
    required String method,
    required Uri uri,
    Map<String, dynamic>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
    String client = "Custom",
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
  void showInspector() {
    _chuckCore.navigateToCallListScreen();
  }

  /// Handle generic http call. Can be used to any http client.
  void addHttpCall(ChuckHttpCall chuckHttpCall) {
    assert(chuckHttpCall.request != null, "Http call request can't be null");
    assert(chuckHttpCall.response != null, "Http call response can't be null");
    _chuckCore.addCall(chuckHttpCall);
  }
}
