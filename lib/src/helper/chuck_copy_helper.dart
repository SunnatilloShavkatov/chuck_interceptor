import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';

class ChuckCopyHelper {
  static void showCopyMenu(BuildContext context, ChuckHttpCall call) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height / 2,
        position.dx + size.width,
        position.dy + size.height,
      ),
      items: [
        PopupMenuItem(
          value: 'copy_curl',
          child: const Row(children: [Icon(Icons.copy), SizedBox(width: 8), Text('Copy cURL request')]),
        ),
      ],
    ).then((value) {
      if (value == 'copy_curl' && context.mounted) {
        _copyCurlToClipboard(context, call);
      }
    });
  }

  static Future<void> _copyCurlToClipboard(BuildContext context, ChuckHttpCall call) async {
    try {
      final curlCommand = call.getCurlCommand();
      await Clipboard.setData(ClipboardData(text: curlCommand));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Curl request copied to clipboard'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error copying curl request'), duration: Duration(seconds: 2)));
      }
    }
  }
}
