import 'package:chuck_interceptor/src/helper/chuck_snack_bar_helper.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/theme/chuck_theme.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_base_call_details_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    if (_call.loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(context.chuckTheme.statusLoading)),
            const SizedBox(height: 16),
            Text('Awaiting response...', style: TextStyle(fontSize: 14, color: context.chuckTheme.secondaryText)),
          ],
        ),
      );
    }

    if (_call.response == null) {
      return Center(
        child: Text('No response received', style: TextStyle(color: context.chuckTheme.secondaryText)),
      );
    }

    final response = _call.response!;
    final headers = response.headers ?? {};
    final String contentType = getContentType(headers) ?? 'Unknown';
    final String bodyContent = formatBody(response.body, contentType);

    return ListView(
      padding: getDetailsListPadding(context),
      children: [
        buildCardSection(
          title: 'Status & Details',
          children: [
            getListRow('Status Code:', response.status == -1 ? 'Error (-1)' : '${response.status}'),
            getListRow('Received:', response.time.toString()),
            getListRow('Bytes Received:', formatBytes(response.size)),
            getListRow('Content-Type:', contentType, copyable: true),
          ],
        ),
        buildCardSection(
          title: 'Response Headers (${headers.length})',
          children: headers.isEmpty
              ? [Text('No response headers', style: TextStyle(fontSize: 13, color: context.chuckTheme.secondaryText))]
              : headers.entries.map((e) => getListRow('${e.key}:', e.value, copyable: true)).toList(),
        ),
        buildCardSection(
          title: 'Response Body',
          trailing: bodyContent.isNotEmpty && bodyContent != 'Body is empty'
              ? InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: bodyContent));
                    ChuckSnackBarHelper.show(
                      context,
                      'Response body copied to clipboard',
                      duration: const Duration(seconds: 1),
                    );
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy, size: 13, color: context.chuckTheme.accent),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.chuckTheme.accent),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.chuckTheme.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.chuckTheme.surfaceBorder, width: 0.5),
              ),
              child: SelectableText(
                bodyContent,
                style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: context.chuckTheme.primaryText),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
