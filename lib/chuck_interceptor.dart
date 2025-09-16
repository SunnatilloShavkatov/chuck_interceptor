import 'dart:io';
import 'package:chuck_interceptor/src/core/chuck_http_adapter.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';

import 'package:chuck_interceptor/src/core/chuck_core.dart';
import 'package:chuck_interceptor/src/core/chuck_dio_interceptor.dart';
import 'package:chuck_interceptor/src/core/chuck_http_client_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

export 'package:chuck_interceptor/src/core/chuck_core.dart';
export 'package:chuck_interceptor/src/core/chuck_dio_interceptor.dart';
export 'package:chuck_interceptor/src/core/chuck_http_client_adapter.dart';
export 'package:chuck_interceptor/src/core/chuck_http_client_extensions.dart';

final class Chuck {
  /// Should user be notified with notification if there's new request catched
  /// by Chuck
  final bool showNotification;

  /// Should inspector be opened on device shake (works only with physical
  /// with sensors)
  final bool showInspectorOnShake;

  /// Icon url for notification
  final String notificationIcon;

  ///Max number of calls that are stored in memory. When count is reached, FIFO
  ///method queue will be used to remove elements.
  final int maxCallsCount;

  GlobalKey<NavigatorState>? _navigatorKey;
  late ChuckCore _chuckCore;
  late ChuckHttpClientAdapter _httpClientAdapter;
  late ChuckHttpAdapter _httpAdapter;

  /// Creates Chuck instance.
  Chuck({
    GlobalKey<NavigatorState>? navigatorKey,
    this.showNotification = true,
    this.showInspectorOnShake = false,
    this.notificationIcon = "@mipmap/ic_launcher",
    this.maxCallsCount = 1000,
  }) {
    _navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>();
    _chuckCore = ChuckCore(
      _navigatorKey,
      maxCallsCount: maxCallsCount,
      showNotification: showNotification,
      notificationIcon: notificationIcon,
      showInspectorOnShake: showInspectorOnShake,
    );
    _httpClientAdapter = ChuckHttpClientAdapter(_chuckCore);
    _httpAdapter = ChuckHttpAdapter(_chuckCore);
  }

  /// Set custom navigation key. This will help if there's route library.
  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _chuckCore.navigatorKey = navigatorKey;
  }

  /// Get currently used navigation key
  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

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

  /// Handle both request and response from http package
  void onHttpResponse(http.Response response, {dynamic body}) {
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
