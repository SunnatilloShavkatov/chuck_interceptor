import 'package:chuck_interceptor/src/core/chuck_core.dart';
import 'package:chuck_interceptor/src/helper/chuck_conversion_helper.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/theme/chuck_theme.dart';
import 'package:chuck_interceptor/src/theme/chuck_theme_data.dart';
import 'package:flutter/material.dart';

class ChuckStatsScreen extends StatelessWidget {
  const ChuckStatsScreen(this.chuckCore, {super.key});

  final ChuckCore chuckCore;

  @override
  Widget build(BuildContext context) => Theme(
    data: ChuckThemeData.attach(Theme.of(context)),
    child: Builder(
      builder: (context) {
        final theme = context.chuckTheme;
        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: context.chuckTheme.background,
            surfaceTintColor: context.chuckTheme.background,
            title: const Text('Chuck - HTTP Inspector - Stats'),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.paddingOf(context).bottom + 16),
            children: [
              _buildOverviewGrid(context),
              const SizedBox(height: 16),
              _buildSectionCard(
                context,
                title: 'Timing & Latency',
                icon: Icons.timer_outlined,
                children: [
                  _buildMetricRow(
                    context,
                    'Average Request Time',
                    ChuckConversionHelper.formatTime(_getAverageRequestTime()),
                  ),
                  _buildMetricRow(
                    context,
                    'Minimum Request Time',
                    ChuckConversionHelper.formatTime(_getMinRequestTime()),
                  ),
                  _buildMetricRow(
                    context,
                    'Maximum Request Time',
                    ChuckConversionHelper.formatTime(_getMaxRequestTime()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                context,
                title: 'Data Transfer',
                icon: Icons.data_usage_outlined,
                children: [
                  _buildMetricRow(context, 'Bytes Sent', ChuckConversionHelper.formatBytes(_getBytesSent())),
                  _buildMetricRow(context, 'Bytes Received', ChuckConversionHelper.formatBytes(_getBytesReceived())),
                  _buildMetricRow(
                    context,
                    'Total Transferred',
                    ChuckConversionHelper.formatBytes(_getBytesSent() + _getBytesReceived()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                context,
                title: 'Security',
                icon: Icons.security_outlined,
                children: [
                  _buildMetricRow(context, 'Secured (HTTPS)', '${_getSecuredRequests()}'),
                  _buildMetricRow(context, 'Unsecured (HTTP)', '${_getUnsecuredRequests()}'),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                context,
                title: 'HTTP Methods',
                icon: Icons.http_outlined,
                children: [
                  _buildMethodRow(context, 'GET', _getRequests('GET'), theme.methodGet),
                  _buildMethodRow(context, 'POST', _getRequests('POST'), theme.methodPost),
                  _buildMethodRow(context, 'PUT', _getRequests('PUT'), theme.methodPut),
                  _buildMethodRow(context, 'DELETE', _getRequests('DELETE'), theme.methodDelete),
                  _buildMethodRow(context, 'PATCH', _getRequests('PATCH'), theme.methodPatch),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _buildOverviewGrid(BuildContext context) {
    final theme = context.chuckTheme;
    final total = _getTotalRequests();
    final success = _getSuccessRequests();
    final redirect = _getRedirectionRequests();
    final error = _getErrorRequests();
    final pending = _getPendingRequests();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Total',
                count: total,
                color: theme.primaryText,
                icon: Icons.compare_arrows,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Pending',
                count: pending,
                color: theme.statusLoading,
                icon: Icons.hourglass_top,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Success',
                count: success,
                color: theme.success,
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Redirect',
                count: redirect,
                color: theme.warning,
                icon: Icons.directions_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Error',
                count: error,
                color: theme.error,
                icon: Icons.error_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    final theme = context.chuckTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: theme.secondaryText, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = context.chuckTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: theme.accent),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.primaryText),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.surfaceBorder),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(BuildContext context, String label, String value) {
    final theme = context.chuckTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: theme.secondaryText)),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.primaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodRow(BuildContext context, String method, int count, Color color) {
    final theme = context.chuckTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(
              method,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const Spacer(),
          Text(
            '$count',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.primaryText),
          ),
        ],
      ),
    );
  }

  int _getTotalRequests() => calls.length;

  int _getSuccessRequests() => calls
      .where((call) => call.response?.status != null && call.response!.status! >= 200 && call.response!.status! < 300)
      .length;

  int _getRedirectionRequests() => calls
      .where((call) => call.response?.status != null && call.response!.status! >= 300 && call.response!.status! < 400)
      .length;

  int _getErrorRequests() => calls
      .where((call) => call.response?.status != null && call.response!.status! >= 400 && call.response!.status! < 600)
      .length;

  int _getPendingRequests() => calls.where((call) => call.loading).length;

  int _getBytesSent() {
    int bytes = 0;
    for (final call in calls) {
      bytes += call.request?.size ?? 0;
    }
    return bytes;
  }

  int _getBytesReceived() {
    int bytes = 0;
    for (final call in calls) {
      if (call.response != null) {
        bytes += call.response!.size;
      }
    }
    return bytes;
  }

  int _getAverageRequestTime() {
    int requestTimeSum = 0;
    int requestsWithDurationCount = 0;
    for (final call in calls) {
      if (call.duration != 0) {
        requestTimeSum += call.duration;
        requestsWithDurationCount++;
      }
    }
    if (requestsWithDurationCount == 0) {
      return 0;
    }
    return requestTimeSum ~/ requestsWithDurationCount;
  }

  int _getMaxRequestTime() {
    int maxRequestTime = 0;
    for (final call in calls) {
      if (call.duration > maxRequestTime) {
        maxRequestTime = call.duration;
      }
    }
    return maxRequestTime;
  }

  int _getMinRequestTime() {
    int minRequestTime = -1;
    for (final call in calls) {
      if (call.duration > 0) {
        if (minRequestTime == -1 || call.duration < minRequestTime) {
          minRequestTime = call.duration;
        }
      }
    }
    return minRequestTime == -1 ? 0 : minRequestTime;
  }

  int _getRequests(String requestType) => calls.where((call) => call.method == requestType).length;

  int _getSecuredRequests() => calls.where((call) => call.secure).length;

  int _getUnsecuredRequests() => calls.where((call) => !call.secure).length;

  List<ChuckHttpCall> get calls => chuckCore.callsSubject.value;
}
