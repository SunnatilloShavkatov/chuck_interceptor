import 'dart:io';

import 'chuck_form_data_file.dart';
import 'chuck_from_data_field.dart';

class ChuckHttpRequest {
  int size = 0;
  DateTime time = DateTime.now();
  Map<String, dynamic> headers = <String, dynamic>{};
  dynamic body = "";
  String? contentType = "";
  List<Cookie> cookies = [];
  Map<String, dynamic> queryParameters = <String, dynamic>{};
  List<ChuckFormDataFile>? formDataFiles;
  List<ChuckFormDataField>? formDataFields;
}
