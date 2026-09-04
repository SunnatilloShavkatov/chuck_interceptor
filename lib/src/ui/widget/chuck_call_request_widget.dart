import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/theme/chuck_theme.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_base_call_details_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChuckCallRequestWidget extends StatefulWidget {
  const ChuckCallRequestWidget(this.call, {super.key});

  final ChuckHttpCall call;

  @override
  State<StatefulWidget> createState() => _ChuckCallRequestWidget();
}

class _ChuckCallRequestWidget extends ChuckBaseCallDetailsWidgetState<ChuckCallRequestWidget> {
  ChuckHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    if (_call.request == null) {
      return Center(
        child: Text('No request data available', style: TextStyle(color: context.chuckTheme.secondaryText)),
      );
    }

    final request = _call.request!;
    final String contentType = getContentType(request.headers) ?? 'Unknown';
    final queryParams = request.queryParameters;
    final headers = request.headers;
    final dynamic body = request.body;
    final String bodyContent = formatBody(body, contentType);

    return ListView(
      padding: getDetailsListPadding(context),
      children: [
        buildCardSection(
          title: 'Request Info',
          children: [
            getListRow('Started:', request.time.toString()),
            getListRow('Bytes Sent:', formatBytes(request.size)),
            getListRow('Content-Type:', contentType, copyable: true),
          ],
        ),
        if (queryParams.isNotEmpty)
          buildCardSection(
            title: 'Query Parameters (${queryParams.length})',
            children: queryParams.entries
                .map((e) => getListRow('${e.key}:', e.value.toString(), copyable: true))
                .toList(),
          ),
        buildCardSection(
          title: 'Request Headers (${headers.length})',
          children: headers.isEmpty
              ? [Text('No headers', style: TextStyle(fontSize: 13, color: context.chuckTheme.secondaryText))]
              : headers.entries.map((e) => getListRow('${e.key}:', e.value.toString(), copyable: true)).toList(),
        ),
        if (request.formDataFields?.isNotEmpty ?? false)
          buildCardSection(
            title: 'Form Data Fields (${request.formDataFields!.length})',
            children: request.formDataFields!.map((f) => getListRow('${f.name}:', f.value, copyable: true)).toList(),
          ),
        if (request.formDataFiles?.isNotEmpty ?? false)
          buildCardSection(
            title: 'Form Data Files (${request.formDataFiles!.length})',
            children: request.formDataFiles!
                .map((f) => getListRow(f.fileName ?? 'file', '${f.contentType} • ${f.length} B'))
                .toList(),
          ),
        buildCardSection(
          title: 'Request Body',
          trailing: bodyContent.isNotEmpty && bodyContent != 'Body is empty'
              ? InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: bodyContent));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Request body copied to clipboard'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
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
