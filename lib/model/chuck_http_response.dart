class ChuckHttpResponse {
  ChuckHttpResponse({
    int? status,
    this.size = 0,
    DateTime? time,
    this.body,
    this.headers,
  }) {
    if (time != null) this.time = time;
    if (status != null) this.status = status;
  }

  int? status = 0;
  int size = 0;
  DateTime time = DateTime.now();
  dynamic body;
  Map<String, String>? headers;

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'size': size,
      'time': time.toString(),
      if (body != null && body is Map) 'body': body,
      'headers': headers,
    };
  }

  factory ChuckHttpResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, String> headers = {};
    json['headers']?.forEach((header, values) {
      headers[header] = values.toString();
    });
    return ChuckHttpResponse(
      time: json['time'] != null ? DateTime.tryParse(json['time']) : null,
      size: json['size'],
      status: json['status'],
      body: json['body'],
      headers: headers,
    );
  }
}
