import 'dart:convert';

import 'package:chuck_interceptor/src/core/chuck_core.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/model/chuck_http_request.dart';
import 'package:chuck_interceptor/src/model/chuck_http_response.dart';
import 'package:http/http.dart' as http;

class ChuckHttpAdapter {
  /// Creates Chuck http adapter
  const ChuckHttpAdapter(this.chuckCore);

  /// ChuckCore instance
  final ChuckCore chuckCore;

  /// Handles http response. It creates both request and response from http call
  void onResponse(http.Response response, {Object? body}) {
    if (response.request == null) {
      return;
    }
    final request = response.request!;

    final ChuckHttpCall call = ChuckHttpCall(response.request.hashCode)
      ..loading = true
      ..client = 'HttpClient (http package)'
      ..uri = request.url.toString()
      ..method = request.method;
    var path = request.url.path;
    if (path.isEmpty) {
      path = '/';
    }
    call
      ..endpoint = path
      ..server = request.url.host;
    if (request.url.scheme == 'https') {
      call.secure = true;
    }

    final ChuckHttpRequest httpRequest = ChuckHttpRequest();

    if (response.request is http.Request) {
      // we are guaranteed` the existence of body and headers
      if (body != null) {
        httpRequest.body = body;
      }
      httpRequest
        ..body = body ?? (response.request! as http.Request).body
        ..size = utf8.encode(httpRequest.body.toString()).length
        ..headers = Map<String, dynamic>.from(response.request!.headers);
    } else if (body == null) {
      httpRequest
        ..size = 0
        ..body = '';
    } else {
      httpRequest
        ..size = utf8.encode(body.toString()).length
        ..body = body;
    }

    httpRequest.time = DateTime.now();

    String? contentType = 'unknown';
    if (httpRequest.headers.containsKey('Content-Type')) {
      contentType = httpRequest.headers['Content-Type'] as String?;
    }

    httpRequest
      ..contentType = contentType
      ..queryParameters = response.request!.url.queryParameters;

    final ChuckHttpResponse httpResponse = ChuckHttpResponse()
      ..status = response.statusCode
      ..body = response.body
      ..size = utf8.encode(response.body).length
      ..time = DateTime.now();
    final Map<String, String> responseHeaders = {};
    response.headers.forEach((header, values) {
      responseHeaders[header] = values;
    });
    httpResponse.headers = responseHeaders;

    call
      ..request = httpRequest
      ..response = httpResponse
      ..loading = false
      ..duration = 0;
    chuckCore.addCall(call);
  }
}
