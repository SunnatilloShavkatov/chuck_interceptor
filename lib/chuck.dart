import 'dart:io';
import 'package:chuck_interceptor/model/chuck_http_call.dart';

import 'package:chuck_interceptor/core/chuck_core.dart';
import 'package:chuck_interceptor/core/chuck_dio_interceptor.dart';
import 'package:chuck_interceptor/core/chuck_http_client_adapter.dart';
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

  GlobalKey<NavigatorState>? _navigatorKey;
  final Box<dynamic>? cacheBox;
  late ChuckCore _chuckCore;
  late ChuckHttpClientAdapter _httpClientAdapter;

  /// Creates Chuck instance.
  Chuck({
    GlobalKey<NavigatorState>? navigatorKey,
    this.cacheBox,
    this.directionality,
    this.darkTheme = false,
    this.maxCacheCount = 0,
    this.maxCallsCount = 1000,
    this.showInspectorOnShake = false,
  }) {
    _navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>();
    _chuckCore = ChuckCore(
      _navigatorKey,
      cacheBox: cacheBox,
      darkTheme: darkTheme,
      maxCallsCount: maxCallsCount,
      maxCacheCount: maxCacheCount,
      directionality: directionality,
      showInspectorOnShake: showInspectorOnShake,
    );
    _httpClientAdapter = ChuckHttpClientAdapter(_chuckCore);
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

  /// Get Dio interceptor which should be applied to Dio instance.
  ChuckDioInterceptor getDioInterceptor() {
    return ChuckDioInterceptor(_chuckCore);
  }

  /// Handle request from HttpClient
  void onHttpClientRequest(HttpClientRequest request, {dynamic body}) {
    _httpClientAdapter.onRequest(request, body: body);
  }

  /// Handle response from HttpClient
  void onHttpClientResponse(HttpClientResponse response, HttpClientRequest request, {dynamic body}) {
    _httpClientAdapter.onResponse(response, request, body: body);
  }

  /// Opens Http calls inspector. This will navigate user to the new fullscreen
  /// page where all listened http calls can be viewed.
  void showInspector() {
    _chuckCore.navigateToCallListScreen();
  }

  /// Handle generic http call. Can be used to any http client.
  void addHttpCall(ChuckHttpCall ChuckHttpCall) {
    assert(ChuckHttpCall.request != null, "Http call request can't be null");
    assert(ChuckHttpCall.response != null, "Http call response can't be null");
    _chuckCore.addCall(ChuckHttpCall);
  }
}
