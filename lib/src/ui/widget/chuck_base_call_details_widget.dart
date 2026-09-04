import 'dart:convert';

import 'package:chuck_interceptor/src/helper/chuck_conversion_helper.dart';
import 'package:chuck_interceptor/src/theme/chuck_theme.dart';
import 'package:chuck_interceptor/src/utils/chuck_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class ChuckBaseCallDetailsWidgetState<T extends StatefulWidget> extends State<T> {
  final JsonEncoder encoder = const JsonEncoder.withIndent('  ');

  Widget getListRow(String name, String value, {bool copyable = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          name,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.chuckTheme.primaryText),
          contextMenuBuilder: (_, editableTextState) => AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: editableTextState.contextMenuButtonItems,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(fontSize: 13, color: context.chuckTheme.secondaryText),
            contextMenuBuilder: (_, editableTextState) => AdaptiveTextSelectionToolbar.buttonItems(
              anchors: editableTextState.contextMenuAnchors,
              buttonItems: editableTextState.contextMenuButtonItems,
            ),
          ),
        ),
        if (copyable && value.isNotEmpty)
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied $name to clipboard'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.copy, size: 14, color: context.chuckTheme.neutral),
            ),
          ),
      ],
    ),
  );

  Widget buildCardSection({required String title, required List<Widget> children, Widget? trailing}) => Container(
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    decoration: BoxDecoration(
      color: context.chuckTheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.chuckTheme.surfaceBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.chuckTheme.primaryText),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );

  String formatBytes(int bytes) => ChuckConversionHelper.formatBytes(bytes);

  String formatDuration(int duration) => ChuckConversionHelper.formatTime(duration);

  String formatBody(Object? body, String? contentType) => ChuckParser.formatBody(body, contentType);

  String? getContentType(Map<String, dynamic>? headers) => ChuckParser.getContentType(headers);

  EdgeInsets getDetailsListPadding(BuildContext context, {bool hasFab = true}) =>
      EdgeInsets.only(top: 8, bottom: MediaQuery.paddingOf(context).bottom + (hasFab ? 84 : 16));
}
