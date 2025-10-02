import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_base_call_details_widget.dart';
import 'package:flutter/material.dart';

class ChuckCallResponseWidget extends StatefulWidget {
  const ChuckCallResponseWidget(this.call, {super.key});

  final ChuckHttpCall call;

  @override
  State<StatefulWidget> createState() => _ChuckCallResponseWidgetState();
}

class _ChuckCallResponseWidgetState extends ChuckBaseCallDetailsWidgetState<ChuckCallResponseWidget> {
  ChuckHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    if (!_call.loading) {
      return Scrollbar(
        controller: PrimaryScrollController.of(context),
        child: CustomScrollView(
          slivers: [
            SliverSafeArea(
              minimum: const EdgeInsets.all(6),
              sliver: SliverList.list(
                children: [..._buildGeneralDataRows(), ..._buildHeadersRows(), ..._buildBodyRows()],
              ),
            ),
          ],
        ),
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text("Awaiting response...")],
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<Widget> _buildGeneralDataRows() {
    final List<Widget> rows = [];
    rows.add(getListRow("Received:", _call.response!.time.toString()));
    rows.add(getListRow("Bytes received:", formatBytes(_call.response!.size)));

    final status = _call.response!.status;
    var statusText = "$status";
    if (status == -1) {
      statusText = "Error";
    }

    rows.add(getListRow("Status:", statusText));
    return rows;
  }

  List<Widget> _buildHeadersRows() {
    final List<Widget> rows = [];
    final headers = _call.response!.headers;
    var headersContent = "Headers are empty";
    if (headers != null && headers.isNotEmpty) {
      headersContent = "";
    }
    rows.add(getListRow("Headers: ", headersContent));
    if (_call.response!.headers != null) {
      _call.response!.headers!.forEach((header, value) {
        rows.add(getListRow("   • $header:", value.toString()));
      });
    }
    return rows;
  }

  List<Widget> _buildBodyRows() {
    final List<Widget> rows = [];

    // Simplified: Show only basic response info and raw body
    final headers = _call.response!.headers;
    final bodyContent = formatBody(_call.response!.body, getContentType(headers));

    rows.add(getListRow("Body:", bodyContent));

    return rows;
  }
}
