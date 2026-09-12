import 'package:chuck_interceptor/src/core/chuck_core.dart';
import 'package:chuck_interceptor/src/helper/chuck_copy_helper.dart';
import 'package:chuck_interceptor/src/helper/chuck_save_helper.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/theme/chuck_theme.dart';
import 'package:chuck_interceptor/src/theme/chuck_theme_data.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_call_error_widget.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_call_overview_widget.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_call_request_widget.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_call_response_preview_widget.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_call_response_widget.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ChuckCallDetailsScreen extends StatefulWidget {
  const ChuckCallDetailsScreen(this.call, this.core, {super.key});

  final ChuckHttpCall call;
  final ChuckCore core;

  @override
  State<ChuckCallDetailsScreen> createState() => _ChuckCallDetailsScreenState();
}

class _ChuckCallDetailsScreenState extends State<ChuckCallDetailsScreen> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) => Theme(
    data: ChuckThemeData.attach(Theme.of(context)),
    child: StreamBuilder<List<ChuckHttpCall>>(
      stream: widget.core.callsSubject,
      initialData: [widget.call],
      builder: (context, callsSnapshot) {
        ChuckHttpCall? currentCall;
        final calls = callsSnapshot.data;
        if (calls != null) {
          for (final c in calls) {
            if (c.id == widget.call.id) {
              currentCall = c;
              break;
            }
          }
        }
        currentCall ??= widget.call;

        return _buildMainWidget(context, currentCall);
      },
    ),
  );

  Widget _buildMainWidget(BuildContext context, ChuckHttpCall call) => DefaultTabController(
    length: 5,
    child: ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: context.chuckTheme.background,
        floatingActionButton: FloatingActionButton(
          backgroundColor: context.chuckTheme.accent,
          foregroundColor: context.chuckTheme.onAccent,
          key: const Key('share_key'),
          onPressed: () async {
            await SharePlus.instance.share(
              ShareParams(subject: 'Request Details', text: await _getSharableResponseString(call)),
            );
          },
          child: const Icon(Icons.share),
        ),
        appBar: AppBar(
          centerTitle: false,
          backgroundColor: context.chuckTheme.background,
          surfaceTintColor: context.chuckTheme.background,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                call.endpoint.isNotEmpty ? call.endpoint : 'HTTP Call Details',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.chuckTheme.primaryText),
              ),
              Text(
                call.server.isNotEmpty ? '${call.method} • ${call.server}' : call.method,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: context.chuckTheme.secondaryText),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.code),
              tooltip: 'Copy cURL request',
              onPressed: () => ChuckCopyHelper.showCopyMenu(context, call),
            ),
          ],
          bottom: TabBar(
            tabAlignment: TabAlignment.fill,
            indicatorColor: context.chuckTheme.accent,
            labelColor: context.chuckTheme.accent,
            unselectedLabelColor: context.chuckTheme.secondaryText,
            tabs: const [
              Tab(icon: Icon(Icons.info_outline, size: 20), text: 'Overview'),
              Tab(icon: Icon(Icons.arrow_upward, size: 20), text: 'Request'),
              Tab(icon: Icon(Icons.arrow_downward, size: 20), text: 'Response'),
              Tab(icon: Icon(Icons.preview_rounded, size: 20), text: 'Preview'),
              Tab(icon: Icon(Icons.warning_amber_rounded, size: 20), text: 'Error'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ChuckCallOverviewWidget(call),
            ChuckCallRequestWidget(call),
            ChuckCallResponseWidget(call),
            ChuckCallResponsePreviewWidget(call),
            ChuckCallErrorWidget(call),
          ],
        ),
      ),
    ),
  );

  Future<String> _getSharableResponseString(ChuckHttpCall call) => ChuckSaveHelper.buildCallLog(call);
}
