import 'package:chuck_interceptor/src/core/chuck_core.dart';
import 'package:chuck_interceptor/src/helper/chuck_save_helper.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_call_response_preview_widget.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_call_response_widget.dart';
import 'package:chuck_interceptor/src/utils/chuck_constants.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_call_error_widget.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_call_overview_widget.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_call_request_widget.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ChuckCallDetailsScreen extends StatefulWidget {
  final ChuckHttpCall call;
  final ChuckCore core;

  const ChuckCallDetailsScreen(this.call, this.core, {super.key});

  @override
  State<ChuckCallDetailsScreen> createState() => _ChuckCallDetailsScreenState();
}

class _ChuckCallDetailsScreenState extends State<ChuckCallDetailsScreen> with SingleTickerProviderStateMixin {
  ChuckHttpCall get call => widget.call;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChuckHttpCall>>(
      stream: widget.core.callsSubject,
      initialData: [widget.call],
      builder: (context, callsSnapshot) {
        if (callsSnapshot.hasData) {
          final call = callsSnapshot.data?.firstWhere((snapshotCall) => snapshotCall.id == widget.call.id);
          if (call != null) {
            return _buildMainWidget();
          } else {
            return _buildErrorWidget();
          }
        } else {
          return _buildErrorWidget();
        }
      },
    );
  }

  Widget _buildMainWidget() {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: ChuckConstants.lightRed,
          foregroundColor: Colors.white,
          key: const Key('share_key'),
          onPressed: () async {
            SharePlus.instance.share(ShareParams(subject: 'Request Details', text: await _getSharableResponseString()));
          },
          child: const Icon(Icons.share),
        ),
        appBar: AppBar(
          centerTitle: false,
          bottom: TabBar(
            isScrollable: false,
            tabAlignment: TabAlignment.fill,
            indicatorColor: ChuckConstants.lightRed,
            tabs: const [
              Tab(icon: Icon(Icons.info_outline), text: "Overview"),
              Tab(icon: Icon(Icons.arrow_upward), text: "Request"),
              Tab(icon: Icon(Icons.arrow_downward), text: "Response"),
              Tab(icon: Icon(Icons.preview_rounded), text: "Preview"),
              Tab(icon: Icon(Icons.warning), text: "Error"),
            ],
          ),
          title: const Text('Chuck - HTTP Call Details'),
        ),
        body: TabBarView(
          children: [
            ChuckCallOverviewWidget(widget.call),
            ChuckCallRequestWidget(widget.call),
            ChuckCallResponseWidget(widget.call),
            ChuckCallResponsePreviewWidget(call),
            ChuckCallErrorWidget(widget.call),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return const Center(child: Text("Failed to load data"));
  }

  Future<String> _getSharableResponseString() async {
    return ChuckSaveHelper.buildCallLog(widget.call);
  }
}
