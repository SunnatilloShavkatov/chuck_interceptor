import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_base_call_details_widget.dart';
import 'package:flutter/material.dart';

class ChuckCallOverviewWidget extends StatefulWidget {
  const ChuckCallOverviewWidget(this.call, {super.key});

  final ChuckHttpCall call;

  @override
  State<StatefulWidget> createState() => _ChuckCallOverviewWidget();
}

class _ChuckCallOverviewWidget extends ChuckBaseCallDetailsWidgetState<ChuckCallOverviewWidget> {
  ChuckHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [
      getListRow('Method: ', _call.method),
      getListRow('Server: ', _call.server),
      getListRow('Endpoint: ', _call.endpoint),
      getListRow('Started:', _call.request!.time.toString()),
      getListRow('Finished:', _call.response!.time.toString()),
      getListRow('Duration:', formatDuration(_call.duration)),
      getListRow('Bytes sent:', formatBytes(_call.request!.size)),
      getListRow('Bytes received:', formatBytes(_call.response!.size)),
      getListRow('Client:', _call.client),
      getListRow('Secure:', _call.secure.toString()),
    ];
    return CustomScrollView(
      slivers: [
        SliverSafeArea(
          minimum: const EdgeInsets.all(6),
          sliver: SliverList.list(children: rows),
        ),
      ],
    );
  }
}
