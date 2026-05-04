import 'package:chuck_interceptor/src/helper/chuck_conversion_helper.dart';
import 'package:chuck_interceptor/src/helper/chuck_copy_helper.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/model/chuck_http_response.dart';
import 'package:chuck_interceptor/src/theme/chuck_theme.dart';
import 'package:flutter/material.dart';

class ChuckCallListItemWidget extends StatelessWidget {
  const ChuckCallListItemWidget(this.call, this.itemClickAction, {super.key});

  final ChuckHttpCall call;
  final void Function(ChuckHttpCall) itemClickAction;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => itemClickAction(call),
    onLongPress: () => _showContextMenu(context),
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
                _buildServerRow(context),
                const SizedBox(height: 4),
                _buildStatsRow(context),
              ],
            ),
          ),
          _buildResponseColumn(context),
        ],
      ),
    ),
  );

  Widget _buildMethodAndEndpointRow(BuildContext context) {
    final Color? textColor = _getEndpointTextColor(context);
    return Row(
      children: [
        Text(call.method, style: TextStyle(fontSize: 16, color: textColor)),
        const SizedBox(width: 10),
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

  Widget _buildServerRow(BuildContext context) => Row(
    children: [
      _getSecuredConnectionIcon(context, call.secure),
      Expanded(
        child: Text(
          call.server,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, color: context.chuckTheme.secondaryText),
        ),
      ),
    ],
  );

  Widget _buildStatsRow(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(
        child: Text(
          _formatTime(call.request!.time),
          style: TextStyle(fontSize: 12, color: context.chuckTheme.secondaryText),
        ),
      ),
      Flexible(
        child: Text(
          ChuckConversionHelper.formatTime(call.duration),
          style: TextStyle(fontSize: 12, color: context.chuckTheme.secondaryText),
        ),
      ),
      Flexible(
        child: Text(
          '${ChuckConversionHelper.formatBytes(call.request!.size)} / '
          '${ChuckConversionHelper.formatBytes(call.response!.size)}',
          style: TextStyle(fontSize: 12, color: context.chuckTheme.secondaryText),
        ),
      ),
    ],
  );

  String _formatTime(DateTime time) =>
      '${formatTimeUnit(time.hour)}:'
      '${formatTimeUnit(time.minute)}:'
      '${formatTimeUnit(time.second)}:'
      '${formatTimeUnit(time.millisecond)}';

  String formatTimeUnit(int timeUnit) => (timeUnit < 10) ? '0$timeUnit' : '$timeUnit';

  Widget _buildResponseColumn(BuildContext context) {
    final List<Widget> widgets = [];
    if (call.loading) {
      widgets
        ..add(
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(context.chuckTheme.accent)),
          ),
        )
        ..add(const SizedBox(height: 4));
    }
    widgets.add(Text(_getStatus(call.response!), style: TextStyle(fontSize: 16, color: _getStatusTextColor(context))));
    return SizedBox(width: 50, child: Column(children: widgets));
  }

  Color? _getStatusTextColor(BuildContext context) {
    final int? status = call.response!.status;
    if (status == -1) {
      return context.chuckTheme.error;
    } else if (status! < 200) {
      return context.chuckTheme.primaryText;
    } else if (status >= 200 && status < 300) {
      return context.chuckTheme.success;
    } else if (status >= 300 && status < 400) {
      return context.chuckTheme.warning;
    } else if (status >= 400 && status < 600) {
      return context.chuckTheme.error;
    } else {
      return context.chuckTheme.primaryText;
    }
  }

  Color? _getEndpointTextColor(BuildContext context) {
    if (call.loading) {
      return context.chuckTheme.neutral;
    } else {
      return _getStatusTextColor(context);
    }
  }

  String _getStatus(ChuckHttpResponse response) {
    if (response.status == -1) {
      return 'ERR';
    } else if (response.status == 0) {
      return '???';
    } else {
      return '${response.status}';
    }
  }

  Widget _getSecuredConnectionIcon(BuildContext context, bool secure) {
    IconData iconData;
    Color iconColor;
    if (secure) {
      iconData = Icons.lock_outline;
      iconColor = context.chuckTheme.success;
    } else {
      iconData = Icons.lock_open;
      iconColor = context.chuckTheme.error;
    }
    return Padding(
      padding: const EdgeInsets.only(right: 3),
      child: Icon(iconData, color: iconColor, size: 12),
    );
  }

  void _showContextMenu(BuildContext context) {
    ChuckCopyHelper.showCopyMenu(context, call);
  }
}
