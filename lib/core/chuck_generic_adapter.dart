import 'dart:convert';

import 'package:chuck_interceptor/core/chuck_core.dart';
import 'package:chuck_interceptor/model/chuck_http_call.dart';
import 'package:chuck_interceptor/model/chuck_http_error.dart';
import 'package:chuck_interceptor/model/chuck_http_request.dart';
import 'package:chuck_interceptor/model/chuck_http_response.dart';
import 'package:dio/dio.dart';

/// Client agnostic adapter. It builds [ChuckHttpCall] objects out of plain
/// values (method, uri, headers, body, status code), so any http client
/// (`package:http`, `chopper`, `retrofit`, a hand written one) can be
/// inspected without Chuck depending on that client.
class ChuckGenericAdapter {
  /// Creates Chuck generic adapter
  ChuckGenericAdapter(this.chuckCore);

  /// ChuckCore instance
  final ChuckCore chuckCore;

  /// Source of generated call ids. Ids count down from `-1`, so they can never
  /// collide with the `hashCode` based ids used by the Dio and `HttpClient`
  /// adapters.
  static int _lastGeneratedId = 0;

  /// Registers a request and returns the id of the created call. Pass that id
  /// to [onResponse] or [onError] once the request finishes.
  int onRequest({
    required String method,
    required Uri uri,
    Map<String, dynamic>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
    String client = "Custom",
    int? id,
  }) {
    final int callId = id ?? --_lastGeneratedId;
    final String path = uri.path.isEmpty ? "/" : uri.path;
    final requestHeaders = Map<String, dynamic>.from(headers ?? const <String, dynamic>{});
    final call = ChuckHttpCall(callId, DateTime.now())
      ..client = client
      ..method = method.toUpperCase()
      ..uri = uri.toString()
      ..endpoint = path
      ..server = uri.host
      ..secure = uri.scheme == "https"
      ..request = ChuckHttpRequest(
        time: DateTime.now(),
        headers: requestHeaders,
        body: body ?? "",
        size: _sizeOf(body),
        contentType: _contentTypeOf(requestHeaders),
        queryParameters: queryParameters ?? uri.queryParameters,
      );
    chuckCore.addCall(call);
    return callId;
  }

  /// Adds a response to the call previously created by [onRequest].
  void onResponse(int callId, {int? statusCode, Map<String, String>? headers, Object? body}) {
    chuckCore.addResponse(
      ChuckHttpResponse(
        status: statusCode,
        headers: headers == null ? null : Map<String, String>.from(headers),
        body: body ?? "",
        size: _sizeOf(body),
        time: DateTime.now(),
      ),
      callId,
    );
  }

  /// Adds an error to the call previously created by [onRequest].
  ///
  /// [ChuckHttpError] holds a [DioException] (that is what the cache
  /// serializes), so errors from other clients are wrapped in one.
  void onError(int callId, Object error, {StackTrace? stackTrace}) {
    final DioException dioError = error is DioException
        ? error
        : DioException(requestOptions: RequestOptions(), error: error, message: error.toString());
    chuckCore.addError(ChuckHttpError(error: dioError, stackTrace: stackTrace), callId);
  }

  /// Logs a finished request and response in a single step. Useful for clients
  /// which only expose the call once it has completed, e.g. `package:http`.
  ///
  /// Returns the id of the created call.
  int onCall({
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
  }) {
    final int callId = onRequest(
      method: method,
      uri: uri,
      headers: requestHeaders,
      body: requestBody,
      queryParameters: queryParameters,
      client: client,
      id: id,
    );
    onResponse(callId, statusCode: statusCode, headers: responseHeaders, body: responseBody);
    if (error != null) {
      onError(callId, error, stackTrace: stackTrace);
    }
    if (duration != null) {
      chuckCore.callsSubject.value.lastWhere((call) => call.id == callId).duration = duration.inMilliseconds;
    }
    return callId;
  }

  static int _sizeOf(Object? body) => body == null ? 0 : utf8.encode(body.toString()).length;

  static String? _contentTypeOf(Map<String, dynamic> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == "content-type") {
        return entry.value?.toString();
      }
    }
    return "unknown";
  }
}
