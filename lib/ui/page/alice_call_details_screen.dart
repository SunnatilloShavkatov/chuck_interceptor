import 'package:chuck_interceptor/core/alice_core.dart';
import 'package:chuck_interceptor/helper/alice_save_helper.dart';
import 'package:chuck_interceptor/model/alice_http_call.dart';
import 'package:chuck_interceptor/ui/widget/alice_call_response_widget.dart';
import 'package:chuck_interceptor/utils/alice_constants.dart';
import 'package:chuck_interceptor/ui/widget/alice_call_error_widget.dart';
import 'package:chuck_interceptor/ui/widget/alice_call_overview_widget.dart';
import 'package:chuck_interceptor/ui/widget/alice_call_request_widget.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:share/share.dart';

class AliceCallDetailsScreen extends StatefulWidget {
  final AliceHttpCall call;
  final AliceCore core;

  const AliceCallDetailsScreen(this.call, this.core);

  @override
  _AliceCallDetailsScreenState createState() => _AliceCallDetailsScreenState();
}

class _AliceCallDetailsScreenState extends State<AliceCallDetailsScreen>
    with SingleTickerProviderStateMixin {
  AliceHttpCall get call => widget.call;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.core.directionality ?? Directionality.of(context),
      child: Theme(
        data: ThemeData(
          brightness: widget.core.brightness,
        ),
        child: StreamBuilder<List<AliceHttpCall>>(
          stream: widget.core.callsSubject,
          initialData: [widget.call],
          builder: (context, callsSnapshot) {
            if (callsSnapshot.hasData) {
              final AliceHttpCall? call = callsSnapshot.data!.firstWhereOrNull(
                  (snapshotCall) => snapshotCall.id == widget.call.id);
              if (call != null) {
                return _buildMainWidget();
              } else {
                return _buildErrorWidget();
              }
            } else {
              return _buildErrorWidget();
            }
          },
        ),
      ),
    );
  }

  Widget _buildMainWidget() {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: AliceConstants.lightRed,
          key: const Key('share_key'),
          onPressed: () async {
            Share.share(
              await _getSharableResponseString(),
              subject: 'Request Details',
            );
          },
          child: const Icon(Icons.share),
        ),
        appBar: AppBar(
          bottom: TabBar(
            indicatorColor: AliceConstants.lightRed,
            tabs: const [
              const Tab(icon: Icon(Icons.info_outline), text: "Overview"),
              const Tab(icon: Icon(Icons.arrow_upward), text: "Request"),
              const Tab(icon: Icon(Icons.arrow_downward), text: "Response"),
              const Tab(icon: Icon(Icons.warning), text: "Error"),
            ],
          ),
          title: const Text('ChuckInterceptor - HTTP Call Details'),
        ),
        body: TabBarView(
          children: [
            AliceCallOverviewWidget(widget.call),
            AliceCallRequestWidget(widget.call),
            AliceCallResponseWidget(widget.call),
            AliceCallErrorWidget(widget.call),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return const Center(child: Text("Failed to load data"));
  }

  Future<String> _getSharableResponseString() async {
    return AliceSaveHelper.buildCallLog(widget.call);
  }
}
