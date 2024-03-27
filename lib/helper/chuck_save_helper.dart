import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:chuck_interceptor/core/chuck_utils.dart';
import 'package:chuck_interceptor/helper/chuck_alert_helper.dart';
import 'package:chuck_interceptor/helper/chuck_conversion_helper.dart';
import 'package:chuck_interceptor/model/chuck_http_call.dart';
import 'package:chuck_interceptor/utils/chuck_parser.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ChuckSaveHelper {
  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  /// Top level method used to save calls to file
  static void saveCalls(
      BuildContext context, List<ChuckHttpCall> calls, Brightness brightness) {
    _checkPermissions(context, calls, brightness);
  }

  static void _checkPermissions(BuildContext context, List<ChuckHttpCall> calls,
      Brightness brightness) async {
    final status = await Permission.storage.status;
    if (status.isGranted) {
      _saveToFile(context, calls, brightness);
    } else {
      final status = await Permission.storage.request();

      if (status.isGranted) {
        _saveToFile(context, calls, brightness);
      } else {
        ChuckAlertHelper.showAlert(
          context,
          "Permission error",
          "Permission not granted. Couldn't save logs.",
          brightness: brightness,
        );
      }
    }
  }

  static Future<String> _saveToFile(
    BuildContext context,
    List<ChuckHttpCall> calls,
    Brightness brightness,
  ) async {
    try {
      if (calls.isEmpty) {
        ChuckAlertHelper.showAlert(
          context,
          "Error",
          "There are no logs to save",
          brightness: brightness,
        );
        return "";
      }
      final bool isAndroid = Platform.isAndroid;

      final Directory externalDir = await (isAndroid
          ? getExternalStorageDirectory() as FutureOr<Directory>
          : getApplicationDocumentsDirectory());
      final String fileName =
          "Chuck_log_${DateTime.now().millisecondsSinceEpoch}.txt";
      final File file = File("${externalDir.path}/$fileName");
      file.createSync();
      final IOSink sink = file.openWrite(mode: FileMode.append);
      sink.write(await _buildChuckLog());
      calls.forEach((ChuckHttpCall call) {
        sink.write(_buildCallLog(call));
      });
      await sink.flush();
      await sink.close();
      ChuckAlertHelper.showAlert(
        context,
        "Success",
        "Successfully saved logs in ${file.path}",
        secondButtonTitle: isAndroid ? "View file" : null,
        secondButtonAction: () => null,
        brightness: brightness,
      );
      return file.path;
    } catch (exception) {
      ChuckAlertHelper.showAlert(
        context,
        "Error",
        "Failed to save http calls to file",
        brightness: brightness,
      );
      ChuckUtils.log(exception.toString());
    }

    return "";
  }

  static Future<String> _buildChuckLog() async {
    final StringBuffer stringBuffer = StringBuffer();
    final packageInfo = await PackageInfo.fromPlatform();
    stringBuffer.write("Chuck - HTTP Inspector\n");
    stringBuffer.write("App name:  ${packageInfo.appName}\n");
    stringBuffer.write("Package: ${packageInfo.packageName}\n");
    stringBuffer.write("Version: ${packageInfo.version}\n");
    stringBuffer.write("Build number: ${packageInfo.buildNumber}\n");
    stringBuffer.write("Generated: ${DateTime.now().toIso8601String()}\n");
    stringBuffer.write("\n");
    return stringBuffer.toString();
  }

  static String _buildCallLog(ChuckHttpCall call) {
    final StringBuffer stringBuffer = StringBuffer();
    stringBuffer.write("===========================================\n");
    stringBuffer.write("Id: ${call.id}\n");
    stringBuffer.write("============================================\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("General data\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Server: ${call.server} \n");
    stringBuffer.write("Method: ${call.method} \n");
    stringBuffer.write("Endpoint: ${call.endpoint} \n");
    stringBuffer.write("Client: ${call.client} \n");
    stringBuffer.write(
      "Duration ${ChuckConversionHelper.formatTime(call.duration)}\n",
    );
    stringBuffer.write("Secured connection: ${call.secure}\n");
    stringBuffer.write("Completed: ${!call.loading} \n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Request\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Request time: ${call.request!.time}\n");
    stringBuffer.write("Request content type: ${call.request!.contentType}\n");
    stringBuffer.write(
      "Request cookies: ${_encoder.convert(call.request!.cookies)}\n",
    );
    stringBuffer.write(
      "Request headers: ${_encoder.convert(call.request!.headers)}\n",
    );
    if (call.request!.queryParameters.isNotEmpty) {
      stringBuffer.write(
        "Request query params: ${_encoder.convert(call.request!.queryParameters)}\n",
      );
    }
    stringBuffer.write(
      "Request size: ${ChuckConversionHelper.formatBytes(call.request!.size)}\n",
    );
    stringBuffer.write(
      "Request body: ${ChuckParser.formatBody(call.request!.body, ChuckParser.getContentType(call.request!.headers))}\n",
    );
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Response\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Response time: ${call.response!.time}\n");
    stringBuffer.write("Response status: ${call.response!.status}\n");
    stringBuffer.write(
      "Response size: ${ChuckConversionHelper.formatBytes(call.response!.size)}\n",
    );
    stringBuffer.write(
      "Response headers: ${_encoder.convert(call.response!.headers)}\n",
    );
    stringBuffer.write(
      "Response body: ${ChuckParser.formatBody(call.response!.body, ChuckParser.getContentType(call.response!.headers))}\n",
    );
    if (call.error != null) {
      stringBuffer.write("--------------------------------------------\n");
      stringBuffer.write("Error\n");
      stringBuffer.write("--------------------------------------------\n");
      stringBuffer.write(
        "Error: ${call.error?.error.toString().replaceAll("Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status\n", "")}\n",
      );
      if (call.error?.stackTrace != null) {
        stringBuffer.write("Error stacktrace: ${call.error!.stackTrace}\n");
      }
    }
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Curl\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write(call.getCurlCommand());
    stringBuffer.write("\n");
    stringBuffer.write("==============================================\n");
    stringBuffer.write("\n");

    return stringBuffer.toString();
  }

  static Future<String> buildCallLog(ChuckHttpCall call) async {
    try {
      return await _buildChuckLog() + _buildCallLog(call);
    } catch (exception) {
      return "Failed to generate call log";
    }
  }
}
