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
  /// Creates dio interceptor
  ChuckDioInterceptor(this.chuckCore);

  /// ChuckCore instance
  final ChuckCore chuckCore;

  /// Handles dio request and creates Chuck http call based on it
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!chuckCore.enabled) {
      handler.next(options);
      return;
    }

    final ChuckHttpCall call = ChuckHttpCall(options.hashCode);

    final Uri uri = options.uri;
    call.method = options.method;
    var path = options.uri.path;
    if (path.isEmpty) {
      path = '/';
    }
    call
      ..endpoint = path
      ..server = uri.host
      ..client = 'Dio'
      ..uri = options.uri.toString();

    if (uri.scheme == 'https') {
      call.secure = true;
    }

    final ChuckHttpRequest request = ChuckHttpRequest();

    final dynamic data = options.data;
    if (data == null) {
      request
        ..size = 0
        ..body = '';
    } else {
      if (data is FormData) {
        request.body = 'Form data';

        if (data.fields.isNotEmpty) {
          request.formDataFields = data.fields
              .map((entry) => ChuckFormDataField(entry.key, entry.value))
              .toList(growable: false);
        }
        if (data.files.isNotEmpty) {
          request.formDataFiles = data.files
              .map(
                (entry) =>
                    ChuckFormDataFile(entry.value.filename, entry.value.contentType.toString(), entry.value.length),
              )
              .toList(growable: false);
        }
      } else if (data is String) {
        request
          ..size = data.length
          ..body = data.length > chuckCore.maxBodySize
              ? '${data.substring(0, chuckCore.maxBodySize)}\n\n[Body truncated: exceeds ${chuckCore.maxBodySize} bytes]'
              : data;
      } else if (data is Map || data is List) {
        try {
          final String jsonStr = jsonEncode(data);
          request
            ..size = jsonStr.length
            ..body = jsonStr.length > chuckCore.maxBodySize
                ? '${jsonStr.substring(0, chuckCore.maxBodySize)}\n\n[Body truncated: exceeds ${chuckCore.maxBodySize} bytes]'
                : data;
        } catch (_) {
          request
            ..body = data
            ..size = 0;
        }
      } else {
        final String dataString = data.toString();
        request
          ..size = dataString.length
          ..body = dataString.length > chuckCore.maxBodySize
              ? '${dataString.substring(0, chuckCore.maxBodySize)}\n\n[Body truncated: exceeds ${chuckCore.maxBodySize} bytes]'
              : dataString;
      }
    }

    request
      ..time = DateTime.now()
      ..headers = options.headers
      ..contentType = options.contentType.toString()
      ..queryParameters = options.queryParameters;

    call
      ..request = request
      ..response = ChuckHttpResponse();

    chuckCore.addCall(call);
    handler.next(options);
  }

  /// Handles dio response and adds data to Chuck http call
  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (!chuckCore.enabled) {
      handler.next(response);
      return;
    }

    final httpResponse = ChuckHttpResponse()..status = response.statusCode;

    if (response.data == null) {
      httpResponse
        ..body = ''
        ..size = 0;
    } else if (response.data is String) {
      final String str = response.data as String;
      httpResponse
        ..size = str.length
        ..body = str.length > chuckCore.maxBodySize
            ? '${str.substring(0, chuckCore.maxBodySize)}\n\n[Body truncated: exceeds ${chuckCore.maxBodySize} bytes]'
            : str;
    } else if (response.data is Map || response.data is List) {
      httpResponse.body = response.data;
      try {
        final String jsonStr = jsonEncode(response.data);
        httpResponse.size = jsonStr.length;
      } catch (_) {
        httpResponse.size = 0;
      }
    } else {
      final String responseDataString = response.data.toString();
      httpResponse
        ..size = responseDataString.length
        ..body = responseDataString.length > chuckCore.maxBodySize
            ? '${responseDataString.substring(0, chuckCore.maxBodySize)}\n\n[Body truncated: exceeds ${chuckCore.maxBodySize} bytes]'
            : responseDataString;
    }

    httpResponse.time = DateTime.now();
    final Map<String, String> headers = {};
    response.headers.map.forEach((header, values) {
      headers[header] = values.join(', ');
    });
    httpResponse.headers = headers;

    chuckCore.addResponse(httpResponse, response.requestOptions.hashCode);
    handler.next(response);
  }

  /// Handles error and adds data to Chuck http call with improved null safety
  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    if (!chuckCore.enabled) {
      handler.next(error);
      return;
    }

    StackTrace? stackTrace;
    if (error is Error) {
      stackTrace = error.stackTrace;
    }

    final httpError = ChuckHttpError(error: error, stackTrace: stackTrace);
    chuckCore.addError(httpError, error.requestOptions.hashCode);
    final httpResponse = ChuckHttpResponse()..time = DateTime.now();

    final errorResponse = error.response;
    if (errorResponse == null) {
      httpResponse.status = -1;
      chuckCore.addResponse(httpResponse, error.requestOptions.hashCode);
    } else {
      httpResponse.status = errorResponse.statusCode;
      if (errorResponse.data == null) {
        httpResponse
          ..body = ''
          ..size = 0;
      } else if (errorResponse.data is String) {
        final String str = errorResponse.data as String;
        httpResponse
          ..size = str.length
          ..body = str.length > chuckCore.maxBodySize
              ? '${str.substring(0, chuckCore.maxBodySize)}\n\n[Body truncated: exceeds ${chuckCore.maxBodySize} bytes]'
              : str;
      } else if (errorResponse.data is Map || errorResponse.data is List) {
        httpResponse.body = errorResponse.data;
        try {
          final String jsonStr = jsonEncode(errorResponse.data);
          httpResponse.size = jsonStr.length;
        } catch (_) {
          httpResponse.size = 0;
        }
      } else {
        final String errorDataString = errorResponse.data.toString();
        httpResponse
          ..size = errorDataString.length
          ..body = errorDataString.length > chuckCore.maxBodySize
              ? '${errorDataString.substring(0, chuckCore.maxBodySize)}\n\n[Body truncated: exceeds ${chuckCore.maxBodySize} bytes]'
              : errorDataString;
      }
      final Map<String, String> headers = {};
      errorResponse.headers.map.forEach((header, values) {
        headers[header] = values.join(', ');
      });
      httpResponse.headers = headers;
      chuckCore.addResponse(httpResponse, errorResponse.requestOptions.hashCode);
    }
    handler.next(error);
  }
}
