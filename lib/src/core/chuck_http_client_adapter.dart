import 'dart:io';

import 'package:chuck_interceptor/src/core/chuck_core.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/model/chuck_http_request.dart';
import 'package:chuck_interceptor/src/model/chuck_http_response.dart';

class ChuckHttpClientAdapter {
  /// Creates Chuck http client adapter
  const ChuckHttpClientAdapter(this.chuckCore);

  /// ChuckCore instance
  final ChuckCore chuckCore;

  /// Handles httpClientRequest and creates http Chuck call from it
  void onRequest(HttpClientRequest request, {Object? body}) {
    if (!chuckCore.enabled) {
      return;
    }

    final ChuckHttpCall call = ChuckHttpCall(request.hashCode)
      ..loading = true
      ..client = 'HttpClient (io package)'
      ..method = request.method
      ..uri = request.uri.toString();

    var path = request.uri.path;
    if (path.isEmpty) {
      path = '/';
    }

    call
      ..endpoint = path
      ..server = request.uri.host;
    if (request.uri.scheme == 'https') {
      call.secure = true;
    }
    final ChuckHttpRequest httpRequest = ChuckHttpRequest();
    if (body == null) {
      httpRequest
        ..size = 0
        ..body = '';
    } else {
      final String bodyStr = body.toString();
      httpRequest
        ..size = bodyStr.length
        ..body = bodyStr.length > chuckCore.maxBodySize
            ? '${bodyStr.substring(0, chuckCore.maxBodySize)}\n\n[Body truncated: exceeds ${chuckCore.maxBodySize} bytes]'
            : body;
    }
    httpRequest.time = DateTime.now();
    final Map<String, dynamic> headers = <String, dynamic>{};

    request.headers.forEach((header, List<String> values) {
      headers[header] = values.join(', ');
    });

    httpRequest.headers = headers;
    String? contentType = 'unknown';
    if (headers.containsKey('content-type')) {
      contentType = headers['content-type'] as String?;
    } else if (headers.containsKey('Content-Type')) {
      contentType = headers['Content-Type'] as String?;
    }

    httpRequest
      ..contentType = contentType
      ..cookies = request.cookies;

    call
      ..request = httpRequest
      ..response = ChuckHttpResponse();
    chuckCore.addCall(call);
  }

  /// Handles httpClientRequest and adds response to http Chuck call
  Future<void> onResponse(HttpClientResponse response, HttpClientRequest request, {Object? body}) async {
    if (!chuckCore.enabled) {
      return;
    }

    final ChuckHttpResponse httpResponse = ChuckHttpResponse()..status = response.statusCode;

    if (body != null) {
      final String bodyStr = body.toString();
      httpResponse
        ..size = bodyStr.length
        ..body = bodyStr.length > chuckCore.maxBodySize
            ? '${bodyStr.substring(0, chuckCore.maxBodySize)}\n\n[Body truncated: exceeds ${chuckCore.maxBodySize} bytes]'
            : body;
    } else {
      httpResponse
        ..body = ''
        ..size = 0;
    }
    httpResponse.time = DateTime.now();
    final Map<String, String> headers = {};
    response.headers.forEach((header, values) {
      headers[header] = values.join(', ');
    });
    httpResponse.headers = headers;
    chuckCore.addResponse(httpResponse, request.hashCode);
  }
}
