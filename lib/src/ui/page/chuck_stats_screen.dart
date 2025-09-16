import 'package:chuck_interceptor/src/core/chuck_core.dart';
import 'package:chuck_interceptor/src/helper/chuck_conversion_helper.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:flutter/material.dart';

class ChuckStatsScreen extends StatelessWidget {
  final ChuckCore chuckCore;

  const ChuckStatsScreen(this.chuckCore, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chuck - HTTP Inspector - Stats")),
      body: ListView(padding: const EdgeInsets.all(8), children: _buildMainListWidgets()),
    );
  }

  List<Widget> _buildMainListWidgets() {
    return [
      _getRow("Total requests:", "${_getTotalRequests()}"),
      _getRow("Pending requests:", "${_getPendingRequests()}"),
      _getRow("Success requests:", "${_getSuccessRequests()}"),
      _getRow("Redirection requests:", "${_getRedirectionRequests()}"),
      _getRow("Error requests:", "${_getErrorRequests()}"),
      _getRow("Bytes send:", ChuckConversionHelper.formatBytes(_getBytesSent())),
      _getRow("Bytes received:", ChuckConversionHelper.formatBytes(_getBytesReceived())),
      _getRow("Average request time:", ChuckConversionHelper.formatTime(_getAverageRequestTime())),
      _getRow("Max request time:", ChuckConversionHelper.formatTime(_getMaxRequestTime())),
      _getRow("Min request time:", ChuckConversionHelper.formatTime(_getMinRequestTime())),
      _getRow("Get requests:", "${_getRequests("GET")} "),
      _getRow("Post requests:", "${_getRequests("POST")} "),
      _getRow("Delete requests:", "${_getRequests("DELETE")} "),
      _getRow("Put requests:", "${_getRequests("PUT")} "),
      _getRow("Patch requests:", "${_getRequests("PATCH")} "),
      _getRow("Secured requests:", "${_getSecuredRequests()}"),
      _getRow("Unsecured requests:", "${_getUnsecuredRequests()}"),
    ];
  }

  Widget _getRow(String label, String value) {
    return Row(
      children: <Widget>[
        Text(label, style: _getLabelTextStyle()),
        const Padding(padding: EdgeInsets.only(left: 10)),
        Text(value, style: _getValueTextStyle()),
      ],
    );
  }

  TextStyle _getLabelTextStyle() {
    return const TextStyle(fontSize: 16);
  }

  TextStyle _getValueTextStyle() {
    return const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  }

  int _getTotalRequests() {
    return calls.length;
  }

  int _getSuccessRequests() => calls
      .where((call) => call.response != null && call.response!.status! >= 200 && call.response!.status! < 300)
      .toList()
      .length;

  int _getRedirectionRequests() => calls
      .where((call) => call.response != null && call.response!.status! >= 300 && call.response!.status! < 400)
      .toList()
      .length;

  int _getErrorRequests() => calls
      .where((call) => call.response != null && call.response!.status! >= 400 && call.response!.status! < 600)
      .toList()
      .length;

  int _getPendingRequests() => calls.where((call) => call.loading).toList().length;

  int _getBytesSent() {
    int bytes = 0;
    calls.forEach((ChuckHttpCall call) {
      bytes += call.request!.size;
    });
    return bytes;
  }

  int _getBytesReceived() {
    int bytes = 0;
    calls.forEach((ChuckHttpCall call) {
      if (call.response != null) {
        bytes += call.response!.size;
      }
    });
    return bytes;
  }

  int _getAverageRequestTime() {
    int requestTimeSum = 0;
    int requestsWithDurationCount = 0;
    calls.forEach((ChuckHttpCall call) {
      if (call.duration != 0) {
        requestTimeSum = call.duration;
        requestsWithDurationCount++;
      }
    });
    if (requestTimeSum == 0) {
      return 0;
    }
    return requestTimeSum ~/ requestsWithDurationCount;
  }

  int _getMaxRequestTime() {
    int maxRequestTime = 0;
    calls.forEach((ChuckHttpCall call) {
      if (call.duration > maxRequestTime) {
        maxRequestTime = call.duration;
      }
    });
    return maxRequestTime;
  }

  int _getMinRequestTime() {
    int minRequestTime = 10000000;
    if (calls.isEmpty) {
      minRequestTime = 0;
    } else {
      calls.forEach((ChuckHttpCall call) {
        if (call.duration != 0 && call.duration < minRequestTime) {
          minRequestTime = call.duration;
        }
      });
    }
    return minRequestTime;
  }

  int _getRequests(String requestType) => calls.where((call) => call.method == requestType).toList().length;

  int _getSecuredRequests() => calls.where((call) => call.secure).toList().length;

  int _getUnsecuredRequests() => calls.where((call) => !call.secure).toList().length;

  List<ChuckHttpCall> get calls => chuckCore.callsSubject.value;
}
