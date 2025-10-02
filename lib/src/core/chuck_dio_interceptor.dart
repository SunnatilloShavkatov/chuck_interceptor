import 'dart:convert';

import 'package:chuck_interceptor/src/core/chuck_core.dart';
import 'package:chuck_interceptor/src/model/chuck_form_data_file.dart';
import 'package:chuck_interceptor/src/model/chuck_from_data_field.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/model/chuck_http_error.dart';
import 'package:chuck_interceptor/src/model/chuck_http_request.dart';
import 'package:chuck_interceptor/src/model/chuck_http_response.dart';
import 'package:dio/dio.dart';

class ChuckDioInterceptor extends InterceptorsWrapper {
  /// ChuckCore instance
  final ChuckCore chuckCore;

  /// Creates dio interceptor
  ChuckDioInterceptor(this.chuckCore);

  /// Handles dio request and creates Chuck http call based on it
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final ChuckHttpCall call = ChuckHttpCall(options.hashCode);

    final Uri uri = options.uri;
    call.method = options.method;
    var path = options.uri.path;
    if (path.isEmpty) {
      path = "/";
    }
    call.endpoint = path;
    call.server = uri.host;
    call.client = "Dio";
    call.uri = options.uri.toString();

    if (uri.scheme == "https") {
      call.secure = true;
    }

    final ChuckHttpRequest request = ChuckHttpRequest();

    final dynamic data = options.data;
    if (data == null) {
      request.size = 0;
      request.body = "";
    } else {
      if (data is FormData) {
        request.body = "Form data";

        if (data.fields.isNotEmpty) {
          // Use map instead of forEach for better performance
          request.formDataFields = data.fields
              .map((entry) => ChuckFormDataField(entry.key, entry.value))
              .toList(growable: false);
        }
        if (data.files.isNotEmpty) {
          // Use map instead of forEach for better performance
          request.formDataFiles = data.files
              .map(
                (entry) =>
                    ChuckFormDataFile(entry.value.filename, entry.value.contentType.toString(), entry.value.length),
              )
              .toList(growable: false);
        }
      } else {
        final String dataString = data.toString();
        request.size = utf8.encode(dataString).length;
        request.body = dataString;
      }
    }

    request.time = DateTime.now();
    request.headers = options.headers;
    request.contentType = options.contentType.toString();
    request.queryParameters = options.queryParameters;

    call.request = request;
    call.response = ChuckHttpResponse();

    chuckCore.addCall(call);
    handler.next(options);
  }

  /// Handles dio response and adds data to Chuck http call
  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final httpResponse = ChuckHttpResponse();
    httpResponse.status = response.statusCode;

    if (response.data == null) {
      httpResponse.body = "";
      httpResponse.size = 0;
    } else {
      final String responseDataString = response.data.toString();
      httpResponse.body = response.data;
      httpResponse.size = utf8.encode(responseDataString).length;
    }

    httpResponse.time = DateTime.now();
    // Use map for better performance instead of forEach
    final Map<String, String> headers = {};
    httpResponse.headers?.forEach((header, values) {
      headers[header] = values.toString();
    });
    httpResponse.headers = headers;

    chuckCore.addResponse(httpResponse, response.requestOptions.hashCode);
    handler.next(response);
  }

  /// Handles error and adds data to Chuck http call with improved null safety
  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    StackTrace? stackTrace;
    if (error is Error) {
      stackTrace = error.stackTrace;
    }

    final httpError = ChuckHttpError(error: error, stackTrace: stackTrace);
    chuckCore.addError(httpError, error.requestOptions.hashCode);
    final httpResponse = ChuckHttpResponse();
    httpResponse.time = DateTime.now();

    final errorResponse = error.response;
    if (errorResponse == null) {
      httpResponse.status = -1;
      chuckCore.addResponse(httpResponse, error.requestOptions.hashCode);
    } else {
      httpResponse.status = errorResponse.statusCode;
      if (errorResponse.data == null) {
        httpResponse.body = "";
        httpResponse.size = 0;
      } else {
        final String errorDataString = errorResponse.data.toString();
        httpResponse.body = errorResponse.data;
        httpResponse.size = utf8.encode(errorDataString).length;
      }
      // Use map for better performance instead of forEach
      final Map<String, String> headers = {};
      httpResponse.headers?.forEach((header, values) {
        headers[header] = values.toString();
      });
      httpResponse.headers = headers;
      chuckCore.addResponse(httpResponse, errorResponse.requestOptions.hashCode);
    }
    handler.next(error);
  }
}
