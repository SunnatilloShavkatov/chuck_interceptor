import 'dart:convert';
import 'dart:io';

import 'package:chuck_interceptor/core/chuck_core.dart';
import 'package:chuck_interceptor/model/chuck_http_call.dart';
import 'package:chuck_interceptor/model/chuck_http_request.dart';
import 'package:chuck_interceptor/model/chuck_http_response.dart';

class ChuckHttpClientAdapter {
  /// ChuckCore instance
  final ChuckCore chuckCore;

  /// Creates Chuck http client adapter
  ChuckHttpClientAdapter(this.chuckCore);

  /// Handles httpClientRequest and creates http Chuck call from it
  void onRequest(HttpClientRequest request, {dynamic body}) {
    final ChuckHttpCall call = ChuckHttpCall(request.hashCode);
    call.loading = true;
    call.client = "HttpClient (io package)";
    call.method = request.method;
    call.uri = request.uri.toString();

    var path = request.uri.path;
    if (path.isEmpty) {
      path = "/";
    }

    call.endpoint = path;
    call.server = request.uri.host;
    if (request.uri.scheme == "https") {
      call.secure = true;
    }
    final ChuckHttpRequest httpRequest = ChuckHttpRequest();
    if (body == null) {
      httpRequest.size = 0;
      httpRequest.body = "";
    } else {
      httpRequest.size = utf8.encode(body.toString()).length;
      httpRequest.body = body;
    }
    httpRequest.time = DateTime.now();
    final Map<String, dynamic> headers = <String, dynamic>{};

    httpRequest.headers.forEach((header, dynamic value) {
      headers[header] = value;
    });

    httpRequest.headers = headers;
    String? contentType = "unknown";
    if (headers.containsKey("Content-Type")) {
      contentType = headers["Content-Type"] as String?;
    }

    httpRequest.contentType = contentType;
    httpRequest.cookies = request.cookies;

    call.request = httpRequest;
    call.response = ChuckHttpResponse();
    chuckCore.addCall(call);
  }

  /// Handles httpClientRequest and adds response to http Chuck call
  void onResponse(HttpClientResponse response, HttpClientRequest request,
      {dynamic body}) async {
    final ChuckHttpResponse httpResponse = ChuckHttpResponse();
    httpResponse.status = response.statusCode;

    if (body != null) {
      httpResponse.body = body;
      httpResponse.size = utf8.encode(body.toString()).length;
    } else {
      httpResponse.body = "";
      httpResponse.size = 0;
    }
    httpResponse.time = DateTime.now();
    final Map<String, String> headers = {};
    response.headers.forEach((header, values) {
      headers[header] = values.toString();
    });
    httpResponse.headers = headers;
    chuckCore.addResponse(httpResponse, request.hashCode);
  }
}
