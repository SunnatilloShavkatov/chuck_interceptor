import 'package:chuck_interceptor/src/core/chuck_core.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/model/chuck_http_error.dart';
import 'package:chuck_interceptor/src/model/chuck_http_request.dart';
import 'package:chuck_interceptor/src/model/chuck_http_response.dart';

/// Client agnostic adapter. It builds [ChuckHttpCall] objects out of plain
/// values (method, uri, headers, body, status code), so any http client can be
/// inspected without Chuck depending on that client.
///
/// `package:http`, `chopper`, `retrofit`, a hand written `Socket` client - they
/// all end up as the same primitives, so they can all be logged through here.
class ChuckGenericAdapter {
  /// Creates Chuck generic adapter
  const new(this.chuckCore);

  /// ChuckCore instance
  final ChuckCore chuckCore;

  /// Source of generated call ids. Ids count down from `-1`, so they can never
  /// collide with the `hashCode` based ids used by the Dio and `HttpClient`
  /// adapters.
  static int _lastGeneratedId = 0;

  /// Registers a request and returns the id of the created call. Pass that id
  /// to [onResponse] or [onError] once the request finishes.
  ///
  /// Returns `-1` when Chuck is disabled.
  int onRequest({
    required String method,
    required Uri uri,
    Map<String, dynamic>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
    String client = 'Custom',
    int? id,
  }) {
    if (!chuckCore.enabled) {
      return -1;
    }

    final int callId = id ?? _nextId();
    final ChuckHttpCall call = _buildCall(
      id: callId,
      method: method,
      uri: uri,
      client: client,
    )
      ..request = _buildRequest(headers: headers, body: body, uri: uri, queryParameters: queryParameters)
      ..response = ChuckHttpResponse();
    chuckCore.addCall(call);
    return callId;
  }

  /// Adds a response to the call previously created by [onRequest].
  void onResponse(
    int callId, {
    int? statusCode,
    Map<String, String>? headers,
    Object? body,
  }) {
    if (!chuckCore.enabled) {
      return;
    }
    chuckCore.addResponse(_buildResponse(statusCode: statusCode, headers: headers, body: body), callId);
  }

  /// Adds an error to the call previously created by [onRequest].
  void onError(int callId, Object error, {StackTrace? stackTrace}) {
    if (!chuckCore.enabled) {
      return;
    }
    chuckCore.addError(ChuckHttpError<Object>(error: error, stackTrace: stackTrace), callId);
  }

  /// Logs a finished request and response in a single step. Useful for clients
  /// which only expose the call once it has completed, e.g. `package:http`:
  ///
  /// ```dart
  /// final response = await http.get(url);
  /// chuck.logHttpCall(
  ///   method: response.request!.method,
  ///   uri: response.request!.url,
  ///   statusCode: response.statusCode,
  ///   responseHeaders: response.headers,
  ///   responseBody: response.body,
  /// );
  /// ```
  ///
  /// Returns the id of the created call, or `-1` when Chuck is disabled.
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
    String client = 'Custom',
    int? id,
  }) {
    if (!chuckCore.enabled) {
      return -1;
    }

    final int callId = id ?? _nextId();
    final ChuckHttpCall call = _buildCall(id: callId, method: method, uri: uri, client: client)
      ..request = _buildRequest(
        headers: requestHeaders,
        body: requestBody,
        uri: uri,
        queryParameters: queryParameters,
      )
      ..response = _buildResponse(statusCode: statusCode, headers: responseHeaders, body: responseBody)
      ..loading = false
      ..duration = duration?.inMilliseconds ?? 0;
    if (error != null) {
      call.error = ChuckHttpError<Object>(error: error, stackTrace: stackTrace);
    }
    chuckCore.addCall(call);
    return callId;
  }

  int _nextId() => --_lastGeneratedId;

  ChuckHttpCall _buildCall({
    required int id,
    required String method,
    required Uri uri,
    required String client,
  }) {
    var path = uri.path;
    if (path.isEmpty) {
      path = '/';
    }
    return ChuckHttpCall(id)
      ..loading = true
      ..client = client
      ..method = method.toUpperCase()
      ..uri = uri.toString()
      ..endpoint = path
      ..server = uri.host
      ..secure = uri.scheme == 'https';
  }

  ChuckHttpRequest _buildRequest({
    required Uri uri,
    Map<String, dynamic>? headers,
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) {
    final Map<String, dynamic> requestHeaders = Map<String, dynamic>.from(headers ?? const <String, dynamic>{});
    final ChuckHttpRequest request = ChuckHttpRequest()
      ..headers = requestHeaders
      ..contentType = _contentTypeOf(requestHeaders)
      ..queryParameters = queryParameters ?? uri.queryParameters
      ..time = DateTime.now();
    _applyBody(body, (size, value) {
      request
        ..size = size
        ..body = value;
    });
    return request;
  }

  ChuckHttpResponse _buildResponse({int? statusCode, Map<String, String>? headers, Object? body}) {
    final ChuckHttpResponse response = ChuckHttpResponse()
      ..status = statusCode
      ..headers = headers == null ? null : Map<String, String>.from(headers)
      ..time = DateTime.now();
    _applyBody(body, (size, value) {
      response
        ..size = size
        ..body = value;
    });
    return response;
  }

  /// Applies [body] through the [ChuckCore.maxBodySize] limit and hands the
  /// resulting size and value to [assign].
  void _applyBody(Object? body, void Function(int size, Object value) assign) {
    if (body == null) {
      assign(0, '');
      return;
    }
    final String bodyStr = body.toString();
    if (bodyStr.length > chuckCore.maxBodySize) {
      assign(
        bodyStr.length,
        '${bodyStr.substring(0, chuckCore.maxBodySize)}\n\n'
        '[Body truncated: exceeds ${chuckCore.maxBodySize} bytes]',
      );
      return;
    }
    assign(bodyStr.length, body);
  }

  String? _contentTypeOf(Map<String, dynamic> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'content-type') {
        return entry.value?.toString();
      }
    }
    return 'unknown';
  }
}
