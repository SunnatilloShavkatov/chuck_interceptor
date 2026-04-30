import 'dart:io';

import 'package:chuck_interceptor/src/model/chuck_form_data_file.dart';
import 'package:chuck_interceptor/src/model/chuck_from_data_field.dart';

class ChuckHttpRequest {
  ChuckHttpRequest({
    this.size = 0,
    DateTime? time,
    Map<String, dynamic>? headers,
    this.body = '',
    this.contentType = '',
    List<Cookie>? cookies,
    Map<String, dynamic>? queryParameters,
    this.formDataFiles,
    this.formDataFields,
  }) : time = time ?? DateTime.now(),
       headers = headers ?? <String, dynamic>{},
       cookies = cookies ?? [],
       queryParameters = queryParameters ?? <String, dynamic>{};

  int size;
  DateTime time;
  Map<String, dynamic> headers;
  dynamic body;
  String? contentType;
  List<Cookie> cookies;
  Map<String, dynamic> queryParameters;
  List<ChuckFormDataFile>? formDataFiles;
  List<ChuckFormDataField>? formDataFields;
}
