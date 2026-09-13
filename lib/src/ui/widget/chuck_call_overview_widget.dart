import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_base_call_details_widget.dart';
import 'package:material_ui/material_ui.dart';

class ChuckCallOverviewWidget extends StatefulWidget {
  const new(this.call, {super.key});

  final ChuckHttpCall call;

  @override
  State<StatefulWidget> createState() => _ChuckCallOverviewWidget();
}

class _ChuckCallOverviewWidget extends ChuckBaseCallDetailsWidgetState<ChuckCallOverviewWidget> {
  ChuckHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    final String startedTime = _call.request?.time != null ? _call.request!.time.toString() : 'Unknown';
    final String finishedTime = _call.response?.time != null
        ? _call.response!.time.toString()
        : (_call.loading ? 'Pending...' : 'Failed');
    final String durationText = _call.loading ? 'Pending' : formatDuration(_call.duration);
    final String sentBytes = formatBytes(_call.request?.size ?? 0);
    final String receivedBytes = formatBytes(_call.response?.size ?? 0);

    return ListView(
      padding: getDetailsListPadding(context),
      children: [
        buildCardSection(
          title: 'General Information',
          children: [
            getListRow('Method:', _call.method.toUpperCase(), copyable: true),
            getListRow('Server:', _call.server, copyable: true),
            getListRow('Endpoint:', _call.endpoint, copyable: true),
            if (_call.uri.isNotEmpty) getListRow('Full URL:', _call.uri, copyable: true),
            getListRow('Client:', _call.client.isNotEmpty ? _call.client : 'Unknown'),
            getListRow('Secured (HTTPS):', _call.secure ? 'Yes' : 'No'),
            getListRow('Status:', _call.loading ? 'Loading...' : '${_call.response?.status ?? "Unknown"}'),
          ],
        ),
        buildCardSection(
          title: 'Timing & Performance',
          children: [
            getListRow('Started:', startedTime),
            getListRow('Finished:', finishedTime),
            getListRow('Duration:', durationText),
          ],
        ),
        buildCardSection(
          title: 'Data Transfer',
          children: [getListRow('Bytes Sent:', sentBytes), getListRow('Bytes Received:', receivedBytes)],
        ),
      ],
    );
  }
}
