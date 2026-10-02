import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:chuck_interceptor/core/chuck_core.dart';
import 'package:chuck_interceptor/core/chuck_utils.dart';
import 'package:chuck_interceptor/helper/chuck_alert_helper.dart';
import 'package:chuck_interceptor/helper/chuck_conversion_helper.dart';
import 'package:chuck_interceptor/model/chuck_http_call.dart';
import 'package:chuck_interceptor/utils/chuck_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:path_provider/path_provider.dart';

class ChuckSaveHelper {
  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  /// Top level method used to save calls to file
  static void saveCalls(BuildContext context, ChuckCore core) {
    _saveToFile(context, core);
  }

  /// Hands [text] to [ChuckCore.onShare], or copies it to the clipboard and
  /// shows a snack bar when no callback was given.
  static Future<void> share(BuildContext context, ChuckCore core, String text) async {
    final onShare = core.onShare;
    if (onShare != null) {
      await onShare(text);
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text("Copied to clipboard")));
    }
  }

  static Future<String> _saveToFile(BuildContext context, ChuckCore core) async {
    final List<ChuckHttpCall> calls = core.callsSubject.value;
    final Brightness brightness = core.brightness;
    try {
      if (calls.isEmpty) {
        ChuckAlertHelper.showAlert(context, "Error", "There are no logs to save", brightness: brightness);
        return "";
      }
      final bool isAndroid = Platform.isAndroid;

      final Directory externalDir = await (isAndroid
          ? getExternalStorageDirectory() as FutureOr<Directory>
          : getApplicationDocumentsDirectory());
      final String fileName = "Chuck_log_${DateTime.now().millisecondsSinceEpoch}.txt";
      final File file = File("${externalDir.path}/$fileName");
      file.createSync();
      final IOSink sink = file.openWrite(mode: FileMode.append);
      sink.write(_buildChuckLog(core));
      calls.forEach((ChuckHttpCall call) {
        sink.write(_buildCallLog(call));
      });
      await sink.flush();
      await sink.close();
      if (context.mounted) {
        ChuckAlertHelper.showAlert(
          context,
          "Success",
          "Successfully saved logs in ${file.path}",
          secondButtonTitle: isAndroid ? "View file" : null,
          secondButtonAction: () => null,
          brightness: brightness,
        );
      }
      return file.path;
    } catch (exception) {
      if (context.mounted) {
        ChuckAlertHelper.showAlert(context, "Error", "Failed to save http calls to file", brightness: brightness);
      }
      ChuckUtils.log(exception.toString());
    }

    return "";
  }

  static String _buildChuckLog(ChuckCore core) {
    final StringBuffer stringBuffer = StringBuffer();
    stringBuffer.write("Chuck - HTTP Inspector\n");
    if (core.appName != null) {
      stringBuffer.write("App name: ${core.appName}\n");
    }
    if (core.appVersion != null) {
      stringBuffer.write("Version: ${core.appVersion}\n");
    }
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
    stringBuffer.write("Duration ${ChuckConversionHelper.formatTime(call.duration)}\n");
    stringBuffer.write("Secured connection: ${call.secure}\n");
    stringBuffer.write("Completed: ${!call.loading} \n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Request\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Request time: ${call.request!.time}\n");
    stringBuffer.write("Request content type: ${call.request!.contentType}\n");
    stringBuffer.write("Request cookies: ${_encoder.convert(call.request!.cookies)}\n");
    stringBuffer.write("Request headers: ${_encoder.convert(call.request!.headers)}\n");
    if (call.request!.queryParameters.isNotEmpty) {
      stringBuffer.write("Request query params: ${_encoder.convert(call.request!.queryParameters)}\n");
    }
    stringBuffer.write("Request size: ${ChuckConversionHelper.formatBytes(call.request!.size)}\n");
    stringBuffer.write(
      "Request body: ${ChuckParser.formatBody(call.request!.body, ChuckParser.getContentType(call.request!.headers))}\n",
    );
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Response\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Response time: ${call.response!.time}\n");
    stringBuffer.write("Response status: ${call.response!.status}\n");
    stringBuffer.write("Response size: ${ChuckConversionHelper.formatBytes(call.response!.size)}\n");
    stringBuffer.write("Response headers: ${_encoder.convert(call.response!.headers)}\n");
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

  static String buildCallLog(ChuckCore core, ChuckHttpCall call) {
    try {
      return _buildChuckLog(core) + _buildCallLog(call);
    } catch (exception) {
      return "Failed to generate call log";
    }
  }
}
