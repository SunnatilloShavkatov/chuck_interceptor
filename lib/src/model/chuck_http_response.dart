class ChuckHttpResponse {
  ChuckHttpResponse({
    this.status = 0,
    this.size = 0,
    DateTime? time,
    this.body,
    this.headers,
  }) : time = time ?? DateTime.now();

  int? status;
  int size;
  DateTime time;
  dynamic body;
  Map<String, String>? headers;
}
