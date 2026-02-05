import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:chuck_interceptor/src/core/chuck_utils.dart';
import 'package:chuck_interceptor/src/helper/chuck_alert_helper.dart';
import 'package:chuck_interceptor/src/helper/chuck_conversion_helper.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/utils/chuck_parser.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

sealed class ChuckSaveHelper {
  const ChuckSaveHelper._();

  /// JsonEncoder instance used to encode request and response headers
  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  /// Top level method used to save calls to file
  static Future<void> saveCalls(BuildContext context, List<ChuckHttpCall> calls, Brightness brightness) async {
    await _checkPermissions(context, calls, brightness);
  }

  static Future<void> _checkPermissions(BuildContext context, List<ChuckHttpCall> calls, Brightness brightness) async {
    final status = await Permission.storage.status;
    if (status.isGranted && context.mounted) {
      await _saveToFile(context, calls, brightness);
    } else {
      final status = await Permission.storage.request();
      if (status.isGranted && context.mounted) {
        await _saveToFile(context, calls, brightness);
      } else if (context.mounted) {
        ChuckAlertHelper.showAlert(
          context,
          'Permission error',
          "Permission not granted. Couldn't save logs.",
          brightness: brightness,
        );
      }
    }
  }

  static Future<String> _saveToFile(BuildContext context, List<ChuckHttpCall> calls, Brightness brightness) async {
    try {
      if (calls.isEmpty) {
        ChuckAlertHelper.showAlert(context, 'Error', 'There are no logs to save', brightness: brightness);
        return '';
      }
      final bool isAndroid = Platform.isAndroid;

      final Directory externalDir = await (isAndroid
          ? getExternalStorageDirectory() as FutureOr<Directory>
          : getApplicationDocumentsDirectory());
      final String fileName = 'Chuck_log_${DateTime.now().millisecondsSinceEpoch}.txt';
      final File file = File('${externalDir.path}/$fileName')..createSync();
      final IOSink sink = file.openWrite(mode: FileMode.append)
        // Write header log
        ..write(await _buildChuckLog());

      // Write all call logs efficiently
      for (final call in calls) {
        sink.write(_buildCallLog(call));
      }

      await sink.flush();
      await sink.close();
      if (context.mounted) {
        ChuckAlertHelper.showAlert(
          context,
          'Success',
          'Successfully saved logs in ${file.path}',
          secondButtonTitle: isAndroid ? 'View file' : null,
          secondButtonAction: () {},
          brightness: brightness,
        );
      }
      return file.path;
    } catch (exception) {
      if (context.mounted) {
        ChuckAlertHelper.showAlert(context, 'Error', 'Failed to save http calls to file', brightness: brightness);
      }
      ChuckUtils.log(exception.toString());
    }

    return '';
  }

  static Future<String> _buildChuckLog() async {
    final StringBuffer stringBuffer = StringBuffer();
    final packageInfo = await PackageInfo.fromPlatform();
    stringBuffer
      ..write('Chuck - HTTP Inspector\n')
      ..write('App name:  ${packageInfo.appName}\n')
      ..write('Package: ${packageInfo.packageName}\n')
      ..write('Version: ${packageInfo.version}\n')
      ..write('Build number: ${packageInfo.buildNumber}\n')
      ..write('Generated: ${DateTime.now().toIso8601String()}\n')
      ..write('\n');
    return stringBuffer.toString();
  }

  static String _buildCallLog(ChuckHttpCall call) {
    final StringBuffer stringBuffer = StringBuffer()
      ..write('===========================================\n')
      ..write('Id: ${call.id}\n')
      ..write('============================================\n')
      ..write('--------------------------------------------\n')
      ..write('General data\n')
      ..write('--------------------------------------------\n')
      ..write('Server: ${call.server} \n')
      ..write('Method: ${call.method} \n')
      ..write('Endpoint: ${call.endpoint} \n')
      ..write('Client: ${call.client} \n')
      ..write('Duration ${ChuckConversionHelper.formatTime(call.duration)}\n')
      ..write('Secured connection: ${call.secure}\n')
      ..write('Completed: ${!call.loading} \n')
      ..write('--------------------------------------------\n')
      ..write('Request\n')
      ..write('--------------------------------------------\n')
      ..write('Request time: ${call.request!.time}\n')
      ..write('Request content type: ${call.request!.contentType}\n')
      ..write('Request cookies: ${_encoder.convert(call.request!.cookies)}\n')
      ..write('Request headers: ${_encoder.convert(call.request!.headers)}\n');
    if (call.request!.queryParameters.isNotEmpty) {
      stringBuffer.write('Request query params: ${_encoder.convert(call.request!.queryParameters)}\n');
    }
    stringBuffer
      ..write('Request size: ${ChuckConversionHelper.formatBytes(call.request!.size)}\n')
      ..write(
        'Request body: ${ChuckParser.formatBody(call.request!.body, ChuckParser.getContentType(call.request!.headers))}\n',
      )
      ..write('--------------------------------------------\n')
      ..write('Response\n')
      ..write('--------------------------------------------\n')
      ..write('Response time: ${call.response!.time}\n')
      ..write('Response status: ${call.response!.status}\n')
      ..write('Response size: ${ChuckConversionHelper.formatBytes(call.response!.size)}\n')
      ..write('Response headers: ${_encoder.convert(call.response!.headers)}\n')
      ..write(
        'Response body: ${ChuckParser.formatBody(call.response!.body, ChuckParser.getContentType(call.response!.headers))}\n',
      );
    if (call.error != null) {
      stringBuffer
        ..write('--------------------------------------------\n')
        ..write('Error\n')
        ..write('--------------------------------------------\n')
        ..write(
          "Error: ${call.error?.error.toString().replaceAll("Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status\n", "")}\n",
        );
      if (call.error?.stackTrace != null) {
        stringBuffer.write('Error stacktrace: ${call.error!.stackTrace}\n');
      }
    }
    stringBuffer
      ..write('--------------------------------------------\n')
      ..write('Curl\n')
      ..write('--------------------------------------------\n')
      ..write(call.getCurlCommand())
      ..write('\n')
      ..write('==============================================\n')
      ..write('\n');

    return stringBuffer.toString();
  }

  static Future<String> buildCallLog(ChuckHttpCall call) async {
    try {
      return await _buildChuckLog() + _buildCallLog(call);
    } catch (exception) {
      return 'Failed to generate call log';
    }
  }
}
