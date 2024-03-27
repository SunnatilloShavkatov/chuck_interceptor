import 'dart:io';
import 'package:chuck_interceptor/core/chuck_http_adapter.dart';
import 'package:chuck_interceptor/model/chuck_http_call.dart';

import 'package:chuck_interceptor/core/chuck_core.dart';
import 'package:chuck_interceptor/core/chuck_dio_interceptor.dart';
import 'package:chuck_interceptor/core/chuck_http_client_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class Chuck {
  /// Should user be notified with notification if there's new request catched
  /// by Chuck
  final bool showNotification;

  /// Should inspector be opened on device shake (works only with physical
  /// with sensors)
  final bool showInspectorOnShake;

  /// Should inspector use dark theme
  final bool darkTheme;

  /// Icon url for notification
  final String notificationIcon;

  ///Max number of calls that are stored in memory. When count is reached, FIFO
  ///method queue will be used to remove elements.
  final int maxCallsCount;

  ///Directionality of app. Directionality of the app will be used if set to null.
  final TextDirection? directionality;

  GlobalKey<NavigatorState>? _navigatorKey;
  late ChuckCore _ChuckCore;
  late ChuckHttpClientAdapter _httpClientAdapter;
  late ChuckHttpAdapter _httpAdapter;

  /// Creates Chuck instance.
  Chuck({
    GlobalKey<NavigatorState>? navigatorKey,
    this.showNotification = true,
    this.showInspectorOnShake = false,
    this.darkTheme = false,
    this.notificationIcon = "@mipmap/ic_launcher",
    this.maxCallsCount = 1000,
    this.directionality,
  }) {
    _navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>();
    _ChuckCore = ChuckCore(
      _navigatorKey,
      showNotification: showNotification,
      showInspectorOnShake: showInspectorOnShake,
      darkTheme: darkTheme,
      notificationIcon: notificationIcon,
      maxCallsCount: maxCallsCount,
      directionality: directionality,
    );
    _httpClientAdapter = ChuckHttpClientAdapter(_ChuckCore);
    _httpAdapter = ChuckHttpAdapter(_ChuckCore);
  }

  /// Set custom navigation key. This will help if there's route library.
  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _ChuckCore.navigatorKey = navigatorKey;
  }

  /// Get currently used navigation key
  GlobalKey<NavigatorState>? getNavigatorKey() {
    return _navigatorKey;
  }

  /// Get Dio interceptor which should be applied to Dio instance.
  ChuckDioInterceptor getDioInterceptor() {
    return ChuckDioInterceptor(_ChuckCore);
  }

  /// Handle request from HttpClient
  void onHttpClientRequest(HttpClientRequest request, {dynamic body}) {
    _httpClientAdapter.onRequest(request, body: body);
  }

  /// Handle response from HttpClient
  void onHttpClientResponse(
    HttpClientResponse response,
    HttpClientRequest request, {
    dynamic body,
  }) {
    _httpClientAdapter.onResponse(response, request, body: body);
  }

  /// Handle both request and response from http package
  void onHttpResponse(http.Response response, {dynamic body}) {
    _httpAdapter.onResponse(response, body: body);
  }

  /// Opens Http calls inspector. This will navigate user to the new fullscreen
  /// page where all listened http calls can be viewed.
  void showInspector() {
    _ChuckCore.navigateToCallListScreen();
  }

  /// Handle generic http call. Can be used to any http client.
  void addHttpCall(ChuckHttpCall ChuckHttpCall) {
    assert(ChuckHttpCall.request != null, "Http call request can't be null");
    assert(ChuckHttpCall.response != null, "Http call response can't be null");
    _ChuckCore.addCall(ChuckHttpCall);
  }
}
