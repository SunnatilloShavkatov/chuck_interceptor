import 'dart:convert';

import 'package:chuck_interceptor/core/chuck_core.dart';
import 'package:chuck_interceptor/model/chuck_form_data_file.dart';
import 'package:chuck_interceptor/model/chuck_from_data_field.dart';
import 'package:chuck_interceptor/model/chuck_http_call.dart';
import 'package:chuck_interceptor/model/chuck_http_error.dart';
import 'package:chuck_interceptor/model/chuck_http_request.dart';
import 'package:chuck_interceptor/model/chuck_http_response.dart';
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
        request.body += "Form data";

        if (data.fields.isNotEmpty == true) {
          final List<ChuckFormDataField> fields = [];
          data.fields.forEach((entry) {
            fields.add(ChuckFormDataField(entry.key, entry.value));
          });
          request.formDataFields = fields;
        }
        if (data.files.isNotEmpty == true) {
          final List<ChuckFormDataFile> files = [];
          data.files.forEach((entry) {
            files.add(ChuckFormDataFile(entry.value.filename,
                entry.value.contentType.toString(), entry.value.length));
          });

          request.formDataFiles = files;
        }
      } else {
        request.size = utf8.encode(data.toString()).length;
        request.body = data;
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
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    final httpResponse = ChuckHttpResponse();
    httpResponse.status = response.statusCode;

    if (response.data == null) {
      httpResponse.body = "";
      httpResponse.size = 0;
    } else {
      httpResponse.body = response.data;
      httpResponse.size = utf8.encode(response.data.toString()).length;
    }

    httpResponse.time = DateTime.now();
    final Map<String, String> headers = {};
    response.headers.forEach((header, values) {
      headers[header] = values.toString();
    });
    httpResponse.headers = headers;

    chuckCore.addResponse(httpResponse, response.requestOptions.hashCode);
    handler.next(response);
  }

  /// Handles error and adds data to Chuck http call
  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    final httpError = ChuckHttpError();
    httpError.error = error;
    if (error is Error) {
      final basicError = error as Error;
      httpError.stackTrace = basicError.stackTrace;
    }
    chuckCore.addError(httpError, error.requestOptions.hashCode);
    final httpResponse = ChuckHttpResponse();
    httpResponse.time = DateTime.now();
    if (error.response == null) {
      httpResponse.status = -1;
      chuckCore.addResponse(httpResponse, error.requestOptions.hashCode);
    } else {
      httpResponse.status = error.response!.statusCode;
      if (error.response!.data == null) {
        httpResponse.body = "";
        httpResponse.size = 0;
      } else {
        httpResponse.body = error.response!.data;
        httpResponse.size = utf8.encode(error.response!.data.toString()).length;
      }
      final Map<String, String> headers = {};
      error.response!.headers.forEach(
        (header, values) {
          headers[header] = values.toString();
        },
      );
      httpResponse.headers = headers;
      chuckCore.addResponse(
        httpResponse,
        error.response!.requestOptions.hashCode,
      );
    }
    handler.next(error);
  }
}
