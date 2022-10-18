import 'dart:async';
import 'dart:convert';

import 'package:chuck_interceptor/core/chuck_utils.dart';
import 'package:chuck_interceptor/model/chuck_http_call.dart';
import 'package:chuck_interceptor/model/chuck_http_request.dart';
import 'package:chuck_interceptor/model/chuck_http_response.dart';
import 'package:chopper/chopper.dart' as chopper;
import 'package:http/http.dart';
import 'chuck_core.dart';

class ChuckChopperInterceptor extends chopper.ResponseInterceptor
    with chopper.RequestInterceptor {
  /// ChuckCore instance
  final ChuckCore chuckCore;

  /// Creates instance of chopper interceptor
  ChuckChopperInterceptor(this.chuckCore);

  /// Creates hashcode based on request
  int getRequestHashCode(BaseRequest baseRequest) {
    int hashCodeSum = 0;
    hashCodeSum += baseRequest.url.hashCode;
    hashCodeSum += baseRequest.method.hashCode;
    if (baseRequest.headers.isNotEmpty) {
      baseRequest.headers.forEach((key, value) {
        hashCodeSum += key.hashCode;
        hashCodeSum += value.hashCode;
      });
    }
    if (baseRequest.contentLength != null) {
      hashCodeSum += baseRequest.contentLength.hashCode;
    }

    return hashCodeSum.hashCode;
  }

  /// Handles chopper request and creates Chuck http call
  @override
  FutureOr<chopper.Request> onRequest(chopper.Request request) async {
    try {
      final baseRequest = await request.toBaseRequest();
      final ChuckHttpCall call = ChuckHttpCall(getRequestHashCode(baseRequest));
      String endpoint = "";
      String server = "";
      if (request.path.isEmpty) {
        final List<String> split = request.path.split("/");
        if (split.length > 2) {
          server = split[1] + split[2];
        }
        if (split.length > 4) {
          endpoint = "/";
          for (int splitIndex = 3; splitIndex < split.length; splitIndex++) {
            // ignore: use_string_buffers
            endpoint += "${split[splitIndex]}/";
          }
          endpoint = endpoint.substring(0, endpoint.length - 1);
        }
      } else {
        endpoint = request.path;
        server = request.url.host;
      }

      call.method = request.method;
      call.endpoint = endpoint;
      call.server = server;
      call.client = "Chopper";
      if (request.url.host.contains("https") || request.path.contains("https")) {
        call.secure = true;
      }

      final ChuckHttpRequest chuckHttpRequest = ChuckHttpRequest();

      if (request.body == null) {
        chuckHttpRequest.size = 0;
        chuckHttpRequest.body = "";
      } else {
        chuckHttpRequest.size = utf8.encode(request.body as String).length;
        chuckHttpRequest.body = request.body;
      }
      chuckHttpRequest.time = DateTime.now();
      chuckHttpRequest.headers = request.headers;

      String? contentType = "unknown";
      if (request.headers.containsKey("Content-Type")) {
        contentType = request.headers["Content-Type"];
      }
      chuckHttpRequest.contentType = contentType;
      chuckHttpRequest.queryParameters = request.parameters;

      call.request = chuckHttpRequest;
      call.response = ChuckHttpResponse();

      chuckCore.addCall(call);
    } catch (exception) {
      ChuckUtils.log(exception.toString());
    }
    return request;
  }

  /// Handles chopper response and adds data to existing Chuck http call
  @override
  FutureOr<chopper.Response> onResponse(chopper.Response response) {
    final httpResponse = ChuckHttpResponse();
    httpResponse.status = response.statusCode;
    if (response.body == null) {
      httpResponse.body = "";
      httpResponse.size = 0;
    } else {
      httpResponse.body = response.body;
      httpResponse.size = utf8.encode(response.body.toString()).length;
    }

    httpResponse.time = DateTime.now();
    final Map<String, String> headers = {};
    response.headers.forEach((header, values) {
      headers[header] = values.toString();
    });
    httpResponse.headers = headers;

    chuckCore.addResponse(
        httpResponse, getRequestHashCode(response.base.request!));
    return response;
  }
}
