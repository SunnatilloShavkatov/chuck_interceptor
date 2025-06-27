import 'dart:convert';

import 'package:chuck_interceptor/src/helper/chuck_conversion_helper.dart';
import 'package:chuck_interceptor/src/utils/chuck_parser.dart';
import 'package:flutter/material.dart';

abstract class ChuckBaseCallDetailsWidgetState<T extends StatefulWidget> extends State<T> {
  final JsonEncoder encoder = const JsonEncoder.withIndent('  ');

  Widget getListRow(String name, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          contextMenuBuilder: (_, editableTextState) {
            return AdaptiveTextSelectionToolbar.buttonItems(
              anchors: editableTextState.contextMenuAnchors,
              buttonItems: editableTextState.contextMenuButtonItems,
            );
          },
        ),
        const SizedBox(width: 6),
        Flexible(
          child: SelectableText(
            value,
            contextMenuBuilder: (_, editableTextState) {
              return AdaptiveTextSelectionToolbar.buttonItems(
                anchors: editableTextState.contextMenuAnchors,
                buttonItems: editableTextState.contextMenuButtonItems,
              );
            },
          ),
        ),
        const Padding(padding: EdgeInsets.only(bottom: 18)),
      ],
    );
  }

  String formatBytes(int bytes) => ChuckConversionHelper.formatBytes(bytes);

  String formatDuration(int duration) => ChuckConversionHelper.formatTime(duration);

  String formatBody(dynamic body, String? contentType) => ChuckParser.formatBody(body, contentType);

  String? getContentType(Map<String, dynamic>? headers) => ChuckParser.getContentType(headers);
}
