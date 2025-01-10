import 'dart:io';

import 'chuck_form_data_file.dart';
import 'chuck_from_data_field.dart';

class ChuckHttpRequest {
  ChuckHttpRequest({
    this.size = 0,
    DateTime? time,
    this.headers = const <String, dynamic>{},
    this.body = "",
    this.contentType,
    this.cookies = const [],
    this.queryParameters = const <String, dynamic>{},
    this.formDataFiles,
    this.formDataFields,
  }) {
    time = time ?? DateTime.now();
  }

  int size = 0;
  DateTime time = DateTime.now();
  Map<String, dynamic> headers = <String, dynamic>{};
  dynamic body = "";
  String? contentType = "";
  List<Cookie> cookies = [];
  Map<String, dynamic> queryParameters = <String, dynamic>{};
  List<ChuckFormDataFile>? formDataFiles;
  List<ChuckFormDataField>? formDataFields;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'size': size,
      'time': time.toString(),
      'headers': headers,
      'body': body,
      'contentType': contentType,
      'cookies': cookies.map((e) => e.toJson()).toList(),
      'queryParameters': queryParameters,
      'formDataFiles': formDataFiles?.map((e) => e.toJson()).toList(),
      'formDataFields': formDataFields?.map((e) => e.toJson()).toList(),
    };
  }

  factory ChuckHttpRequest.fromJson(Map<String, dynamic> json) {
    return ChuckHttpRequest(
      size: json['size'],
      time: json['time'] != null ? DateTime.parse(json['time']) : null,
      headers: json['headers'],
      body: json['body'],
      contentType: json['contentType'],
      cookies: json['cookies'] != null ? List<Cookie>.from(json['cookies'].map((x) => Cookie("", "").fromJson(x))) : [],
      queryParameters: json['queryParameters'],
      formDataFiles: json['formDataFiles'] != null
          ? List<ChuckFormDataFile>.from(json['formDataFiles'].map((x) => ChuckFormDataFile.fromJson(x)))
          : null,
      formDataFields: json['formDataFields'] != null
          ? List<ChuckFormDataField>.from(json['formDataFields'].map((x) => ChuckFormDataField.fromJson(x)))
          : null,
    );
  }
}

extension CookieExtension on Cookie {
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'value': value,
      'expires': expires.toString(),
      'maxAge': maxAge,
      'domain': domain,
      'path': path,
      'secure': secure,
      'httpOnly': httpOnly,
      'sameSite': sameSite.toString(),
    };
  }

  Cookie fromJson(Map<String, dynamic> json) {
    return Cookie(json['name'], json['value'])
      ..expires = DateTime.parse(json['expires'])
      ..maxAge = json['maxAge']
      ..domain = json['domain']
      ..path = json['path']
      ..secure = json['secure']
      ..httpOnly = json['httpOnly']
      ..sameSite = json['sameSite'];
  }
}
