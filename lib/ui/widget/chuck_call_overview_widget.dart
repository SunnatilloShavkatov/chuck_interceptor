import 'package:chuck_interceptor/model/chuck_http_call.dart';
import 'package:chuck_interceptor/ui/widget/chuck_base_call_details_widget.dart';
import 'package:flutter/material.dart';

class ChuckCallOverviewWidget extends StatefulWidget {
  final ChuckHttpCall call;

  const ChuckCallOverviewWidget(this.call);

  @override
  State<StatefulWidget> createState() {
    return _ChuckCallOverviewWidget();
  }
}

class _ChuckCallOverviewWidget
    extends ChuckBaseCallDetailsWidgetState<ChuckCallOverviewWidget> {
  ChuckHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [];
    rows.add(getListRow("Method: ", _call.method));
    rows.add(getListRow("Server: ", _call.server));
    rows.add(getListRow("Endpoint: ", _call.endpoint));
    rows.add(getListRow("Started:", _call.request!.time.toString()));
    rows.add(getListRow("Finished:", _call.response!.time.toString()));
    rows.add(getListRow("Duration:", formatDuration(_call.duration)));
    rows.add(getListRow("Bytes sent:", formatBytes(_call.request!.size)));
    rows.add(getListRow("Bytes received:", formatBytes(_call.response!.size)));
    rows.add(getListRow("Client:", _call.client));
    rows.add(getListRow("Secure:", _call.secure.toString()));
    return ListView(
      padding: const EdgeInsets.all(6),
      children: rows,
    );
  }
}
