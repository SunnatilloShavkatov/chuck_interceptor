import 'package:chuck_interceptor/src/helper/chuck_conversion_helper.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/model/chuck_http_response.dart';
import 'package:chuck_interceptor/src/utils/chuck_constants.dart';
import 'package:flutter/material.dart';

class ChuckCallListItemWidget extends StatelessWidget {
  final ChuckHttpCall call;
  final Function itemClickAction;

  const ChuckCallListItemWidget(this.call, this.itemClickAction, {super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => itemClickAction(call),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMethodAndEndpointRow(context),
                  const SizedBox(height: 4),
                  _buildServerRow(),
                  const SizedBox(height: 4),
                  _buildStatsRow(),
                ],
              ),
            ),
            _buildResponseColumn(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodAndEndpointRow(BuildContext context) {
    final Color? textColor = _getEndpointTextColor(context);
    return Row(
      children: [
        Text(call.method, style: TextStyle(fontSize: 16, color: textColor)),
        SizedBox(width: 10),
        Flexible(
          child: Text(
            call.endpoint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16, color: textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildServerRow() {
    return Row(
      children: [
        _getSecuredConnectionIcon(call.secure),
        Expanded(
          child: Text(call.server, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(_formatTime(call.request!.time), style: const TextStyle(fontSize: 12))),
        Flexible(child: Text(ChuckConversionHelper.formatTime(call.duration), style: const TextStyle(fontSize: 12))),
        Flexible(
          child: Text(
            "${ChuckConversionHelper.formatBytes(call.request!.size)} / "
            "${ChuckConversionHelper.formatBytes(call.response!.size)}",
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return "${formatTimeUnit(time.hour)}:"
        "${formatTimeUnit(time.minute)}:"
        "${formatTimeUnit(time.second)}:"
        "${formatTimeUnit(time.millisecond)}";
  }

  String formatTimeUnit(int timeUnit) {
    return (timeUnit < 10) ? "0$timeUnit" : "$timeUnit";
  }

  Widget _buildResponseColumn(BuildContext context) {
    final List<Widget> widgets = [];
    if (call.loading) {
      widgets.add(
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(ChuckConstants.lightRed)),
        ),
      );
      widgets.add(const SizedBox(height: 4));
    }
    widgets.add(Text(_getStatus(call.response!), style: TextStyle(fontSize: 16, color: _getStatusTextColor(context))));
    return SizedBox(width: 50, child: Column(children: widgets));
  }

  Color? _getStatusTextColor(BuildContext context) {
    final int? status = call.response!.status;
    if (status == -1) {
      return ChuckConstants.red;
    } else if (status! < 200) {
      return Theme.of(context).textTheme.bodyLarge!.color;
    } else if (status >= 200 && status < 300) {
      return ChuckConstants.green;
    } else if (status >= 300 && status < 400) {
      return ChuckConstants.orange;
    } else if (status >= 400 && status < 600) {
      return ChuckConstants.red;
    } else {
      return Theme.of(context).textTheme.bodyLarge!.color;
    }
  }

  Color? _getEndpointTextColor(BuildContext context) {
    if (call.loading) {
      return ChuckConstants.grey;
    } else {
      return _getStatusTextColor(context);
    }
  }

  String _getStatus(ChuckHttpResponse response) {
    if (response.status == -1) {
      return "ERR";
    } else if (response.status == 0) {
      return "???";
    } else {
      return "${response.status}";
    }
  }

  Widget _getSecuredConnectionIcon(bool secure) {
    IconData iconData;
    Color iconColor;
    if (secure) {
      iconData = Icons.lock_outline;
      iconColor = ChuckConstants.green;
    } else {
      iconData = Icons.lock_open;
      iconColor = ChuckConstants.red;
    }
    return Padding(
      padding: const EdgeInsets.only(right: 3),
      child: Icon(iconData, color: iconColor, size: 12),
    );
  }
}
