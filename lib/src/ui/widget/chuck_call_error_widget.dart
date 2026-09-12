import 'package:chuck_interceptor/src/helper/chuck_snack_bar_helper.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/theme/chuck_theme.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_base_call_details_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChuckCallErrorWidget extends StatefulWidget {
  const ChuckCallErrorWidget(this.call, {super.key});

  final ChuckHttpCall call;

  @override
  State<StatefulWidget> createState() => _ChuckCallErrorWidgetState();
}

class _ChuckCallErrorWidgetState extends ChuckBaseCallDetailsWidgetState<ChuckCallErrorWidget> {
  ChuckHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    if (_call.error == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: context.chuckTheme.success),
            const SizedBox(height: 12),
            Text(
              'No error detected for this call',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.chuckTheme.primaryText),
            ),
          ],
        ),
      );
    }

    final dynamic error = _call.error!.error;
    var errorText = 'No error details';
    if (error != null) {
      errorText = error.toString().replaceAll(
        'Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status\n',
        '',
      );
    }
    final StackTrace? stackTrace = _call.error!.stackTrace;

    return ListView(
      padding: getDetailsListPadding(context),
      children: [
        buildCardSection(
          title: 'Error Details',
          trailing: InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: errorText));
              ChuckSnackBarHelper.show(context, 'Error copied to clipboard', duration: const Duration(seconds: 1));
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, size: 13, color: context.chuckTheme.error),
                  const SizedBox(width: 4),
                  Text(
                    'Copy',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.chuckTheme.error),
                  ),
                ],
              ),
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.chuckTheme.errorPreviewBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.chuckTheme.errorPreviewBorder),
              ),
              child: SelectableText(errorText, style: TextStyle(fontSize: 13, color: context.chuckTheme.primaryText)),
            ),
          ],
        ),
        if (stackTrace != null)
          buildCardSection(
            title: 'Stack Trace',
            trailing: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: stackTrace.toString()));
                ChuckSnackBarHelper.show(
                  context,
                  'Stack trace copied to clipboard',
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
            ),
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
                  stackTrace.toString(),
                  style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: context.chuckTheme.secondaryText),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
