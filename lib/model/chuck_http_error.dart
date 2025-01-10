class ChuckHttpError {
  ChuckHttpError({
    this.error,
    this.stackTrace,
  });

  dynamic error;
  StackTrace? stackTrace;

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'stackTrace': stackTrace.toString(),
    };
  }

  factory ChuckHttpError.fromJson(Map<String, dynamic> json) {
    return ChuckHttpError()
      ..error = json['error'];
  }
}
