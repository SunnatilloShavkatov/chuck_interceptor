import 'dart:convert' show JsonEncoder;
import 'dart:io' show Directory, File, FileMode, IOSink;

import 'package:chuck_interceptor/src/core/chuck_utils.dart';
import 'package:chuck_interceptor/src/helper/chuck_alert_helper.dart';
import 'package:chuck_interceptor/src/helper/chuck_conversion_helper.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/model/chuck_package_info.dart';
import 'package:chuck_interceptor/src/model/chuck_share_content.dart';
import 'package:chuck_interceptor/src/utils/chuck_parser.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

final class ChuckSaveHelper {
  const new _();

  /// JsonEncoder instance used to encode request and response headers
  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  /// Top level method used to save calls to file
  static Future<void> saveCalls(
    BuildContext context,
    List<ChuckHttpCall> calls,
    Brightness brightness, {
    ChuckPackageInfo? packageInfo,
    ChuckShareCallback? onShare,
  }) async {
    await _saveToFile(context, calls, brightness, packageInfo, onShare);
  }

  static Future<String> _saveToFile(
    BuildContext context,
    List<ChuckHttpCall> calls,
    Brightness brightness,
    ChuckPackageInfo? packageInfo,
    ChuckShareCallback? onShare,
  ) async {
    try {
      if (calls.isEmpty) {
        ChuckAlertHelper.showAlert(context, 'Error', 'There are no logs to save', brightness: brightness);
        return '';
      }

      final Directory dir = await getApplicationDocumentsDirectory();
      final String fileName = 'chuck_log_${DateTime.now().millisecondsSinceEpoch}.txt';
      final File file = File('${dir.path}/$fileName')..createSync(recursive: true);
      final IOSink sink = file.openWrite(mode: FileMode.append)
        // Write header log
        ..write(_buildChuckLog(packageInfo));

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
          firstButtonTitle: 'OK',
          secondButtonTitle: onShare == null ? null : 'Share',
          secondButtonAction: onShare == null
              ? null
              : () async {
                  await onShare(ChuckShareContent(subject: 'Chuck HTTP Inspector Logs', filePath: file.path));
                },
          brightness: brightness,
        );
      }
      return file.path;
    } catch (exception) {
      if (context.mounted) {
        ChuckAlertHelper.showAlert(
          context,
          'Error',
          'Failed to save http calls to file: $exception',
          brightness: brightness,
        );
      }
      ChuckUtils.log('Error saving HTTP calls: $exception');
    }

    return '';
  }

  static String _buildChuckLog(ChuckPackageInfo? packageInfo) {
    final StringBuffer stringBuffer = StringBuffer()..write('Chuck - HTTP Inspector\n');
    if (packageInfo != null) {
      stringBuffer
        ..write('App name:  ${packageInfo.appName}\n')
        ..write('Package: ${packageInfo.packageName}\n')
        ..write('Version: ${packageInfo.version}\n')
        ..write('Build number: ${packageInfo.buildNumber}\n');
    }
    stringBuffer
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
      ..write('Duration: ${ChuckConversionHelper.formatTime(call.duration)}\n')
      ..write('Secured connection: ${call.secure}\n')
      ..write('Completed: ${!call.loading} \n')
      ..write('--------------------------------------------\n')
      ..write('Request\n')
      ..write('--------------------------------------------\n')
      ..write('Request time: ${call.request?.time}\n')
      ..write('Request content type: ${call.request?.contentType}\n')
      ..write('Request cookies: ${_encoder.convert(call.request?.cookies ?? [])}\n')
      ..write('Request headers: ${_encoder.convert(call.request?.headers ?? {})}\n');

    if (call.request?.queryParameters.isNotEmpty ?? false) {
      stringBuffer.write('Request query params: ${_encoder.convert(call.request!.queryParameters)}\n');
    }

    stringBuffer
      ..write('Request size: ${ChuckConversionHelper.formatBytes(call.request?.size ?? 0)}\n')
      ..write(
        'Request body: ${ChuckParser.formatBody(call.request?.body, ChuckParser.getContentType(call.request?.headers))}\n',
      )
      ..write('--------------------------------------------\n')
      ..write('Response\n')
      ..write('--------------------------------------------\n')
      ..write('Response time: ${call.response?.time}\n')
      ..write('Response status: ${call.response?.status}\n')
      ..write('Response size: ${ChuckConversionHelper.formatBytes(call.response?.size ?? 0)}\n')
      ..write('Response headers: ${_encoder.convert(call.response?.headers ?? {})}\n')
      ..write(
        'Response body: ${ChuckParser.formatBody(call.response?.body, ChuckParser.getContentType(call.response?.headers))}\n',
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

  static String buildCallLog(ChuckHttpCall call, {ChuckPackageInfo? packageInfo}) {
    try {
      return _buildChuckLog(packageInfo) + _buildCallLog(call);
    } catch (exception) {
      return 'Failed to generate call log: $exception';
    }
  }
}
