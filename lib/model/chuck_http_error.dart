import 'package:dio/dio.dart';

class ChuckHttpError {
  ChuckHttpError({
    this.error,
    this.stackTrace,
  });

  DioException? error;
  StackTrace? stackTrace;

  Map<String, dynamic> toJson() {
    return {
      'error': error?.toJson(),
      'stackTrace': stackTrace.toString(),
    };
  }

  factory ChuckHttpError.fromJson(Map<String, dynamic> json) {
    return ChuckHttpError(error: json['error'] != null ? getFromJson(json['error']) : null);
  }
}

DioException getFromJson(Map<String, dynamic> json) {
  return DioException(
    type: DioExceptionType.values[json['type']],
    requestOptions: RequestOptions(),
    response: Response(
      requestOptions: RequestOptions(),
      data: json['response'],
    ),
    message: json['message'],
  );
}

extension DioExceptionExt on DioException {
  Map<String, dynamic> toJson() {
    return {
      'response': response?.data?.toString(),
      'type': type.index,
      'message': message,
    };
  }
}
