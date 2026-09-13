import 'package:chuck_interceptor/src/helper/chuck_conversion_helper.dart';
import 'package:chuck_interceptor/src/helper/chuck_copy_helper.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/theme/chuck_theme.dart';
import 'package:material_ui/material_ui.dart';

class ChuckCallListItemWidget extends StatelessWidget {
  const new(this.call, this.itemClickAction, {super.key});

  final ChuckHttpCall call;
  final void Function(ChuckHttpCall) itemClickAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    child: Material(
      color: context.chuckTheme.surface,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => itemClickAction(call),
        onLongPress: () => _showContextMenu(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.chuckTheme.surfaceBorder),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                spacing: 8,
                children: [
                  _buildMethodBadge(context),
                  Expanded(
                    child: Text(
                      call.endpoint.isNotEmpty ? call.endpoint : '/',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.chuckTheme.primaryText,
                      ),
                    ),
                  ),
                  _buildStatusBadge(context),
                ],
              ),
              _buildServerRow(context),
              Divider(height: 1, thickness: 0.5, color: context.chuckTheme.surfaceBorder),
              _buildStatsRow(context),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildMethodBadge(BuildContext context) {
    final methodColor = context.chuckTheme.getMethodColor(call.method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: methodColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: methodColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        call.method.isNotEmpty ? call.method.toUpperCase() : 'REQ',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: methodColor, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    if (call.loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: context.chuckTheme.statusLoading.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: context.chuckTheme.statusLoading.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(context.chuckTheme.statusLoading),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'WAIT',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.chuckTheme.statusLoading),
            ),
          ],
        ),
      );
    }

    final int? status = call.response?.status;
    final Color statusColor = context.chuckTheme.getStatusColor(status);
    final String statusText = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
      ),
    );
  }

  String _getStatusText(int? status) {
    if (status == null || status == -1) {
      return 'ERR';
    } else if (status == 0) {
      return '???';
    }
    return '$status';
  }

  Widget _buildServerRow(BuildContext context) => Row(
    children: [
      Icon(
        call.secure ? Icons.lock_outline : Icons.lock_open,
        color: call.secure ? context.chuckTheme.success : context.chuckTheme.warning,
        size: 13,
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          call.server.isNotEmpty ? call.server : (call.uri.isNotEmpty ? call.uri : 'unknown server'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: context.chuckTheme.secondaryText),
        ),
      ),
    ],
  );

  Widget _buildStatsRow(BuildContext context) {
    final DateTime? reqTime = call.request?.time;
    final String timeString = reqTime != null ? _formatTime(reqTime) : '-';
    final String durationString = call.loading ? 'loading' : ChuckConversionHelper.formatTime(call.duration);
    final String sentBytes = ChuckConversionHelper.formatBytes(call.request?.size ?? 0);
    final String receivedBytes = ChuckConversionHelper.formatBytes(call.response?.size ?? 0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 12, color: context.chuckTheme.neutral),
            const SizedBox(width: 4),
            Text(timeString, style: TextStyle(fontSize: 11, color: context.chuckTheme.secondaryText)),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 12, color: context.chuckTheme.neutral),
            const SizedBox(width: 4),
            Text(durationString, style: TextStyle(fontSize: 11, color: context.chuckTheme.secondaryText)),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert, size: 12, color: context.chuckTheme.neutral),
            const SizedBox(width: 4),
            Text(
              '$sentBytes / $receivedBytes',
              style: TextStyle(fontSize: 11, color: context.chuckTheme.secondaryText),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime time) =>
      '${formatTimeUnit(time.hour)}:'
      '${formatTimeUnit(time.minute)}:'
      '${formatTimeUnit(time.second)}';

  String formatTimeUnit(int timeUnit) => (timeUnit < 10) ? '0$timeUnit' : '$timeUnit';

  void _showContextMenu(BuildContext context) {
    ChuckCopyHelper.showCopyMenu(context, call);
  }
}
