import 'dart:convert';

import 'package:chuck_interceptor/core/chuck_core.dart';
import 'package:chuck_interceptor/model/chuck_http_call.dart';
import 'package:chuck_interceptor/model/chuck_http_request.dart';
import 'package:chuck_interceptor/model/chuck_http_response.dart';
import 'package:http/http.dart' as http;

class ChuckHttpAdapter {
  /// ChuckCore instance
  final ChuckCore chuckCore;

  /// Creates Chuck http adapter
  ChuckHttpAdapter(this.chuckCore);

  /// Handles http response. It creates both request and response from http call
  void onResponse(http.Response response, {dynamic body}) {
    if (response.request == null) {
      return;
    }
    final request = response.request!;

    final ChuckHttpCall call = ChuckHttpCall(response.request.hashCode);
    call.loading = true;
    call.client = "HttpClient (http package)";
    call.uri = request.url.toString();
    call.method = request.method;
    var path = request.url.path;
    if (path.isEmpty) {
      path = "/";
    }
    call.endpoint = path;

    call.server = request.url.host;
    if (request.url.scheme == "https") {
      call.secure = true;
    }

    final ChuckHttpRequest httpRequest = ChuckHttpRequest();

    if (response.request is http.Request) {
      // we are guaranteed` the existence of body and headers
      if (body != null) {
        httpRequest.body = body;
      }
      // ignore: cast_nullable_to_non_nullable
      httpRequest.body = body ?? (response.request as http.Request).body ?? "";
      httpRequest.size = utf8.encode(httpRequest.body.toString()).length;
      httpRequest.headers =
          Map<String, dynamic>.from(response.request!.headers);
    } else if (body == null) {
      httpRequest.size = 0;
      httpRequest.body = "";
    } else {
      httpRequest.size = utf8.encode(body.toString()).length;
      httpRequest.body = body;
    }

    httpRequest.time = DateTime.now();

    String? contentType = "unknown";
    if (httpRequest.headers.containsKey("Content-Type")) {
      contentType = httpRequest.headers["Content-Type"] as String?;
    }

    httpRequest.contentType = contentType;

    httpRequest.queryParameters = response.request!.url.queryParameters;

    final ChuckHttpResponse httpResponse = ChuckHttpResponse();
    httpResponse.status = response.statusCode;
    httpResponse.body = response.body;

    httpResponse.size = utf8.encode(response.body.toString()).length;
    httpResponse.time = DateTime.now();
    final Map<String, String> responseHeaders = {};
    response.headers.forEach((header, values) {
      responseHeaders[header] = values.toString();
    });
    httpResponse.headers = responseHeaders;

    call.request = httpRequest;
    call.response = httpResponse;

    call.loading = false;
    call.duration = 0;
    chuckCore.addCall(call);
  }
}
