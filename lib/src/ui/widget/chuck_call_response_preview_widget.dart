import 'dart:convert';

import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_json_viewer.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_base_call_details_widget.dart';
import 'package:flutter/material.dart';

class ChuckCallResponsePreviewWidget extends StatefulWidget {
  const ChuckCallResponsePreviewWidget(this.call, {super.key});

  final ChuckHttpCall call;

  @override
  State<StatefulWidget> createState() => _ChuckCallResponsePreviewWidgetState();
}

class _ChuckCallResponsePreviewWidgetState extends ChuckBaseCallDetailsWidgetState<ChuckCallResponsePreviewWidget> {
  ChuckHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    if (!_call.loading && _call.response != null) {
      return Scrollbar(
        controller: PrimaryScrollController.of(context),
        child: CustomScrollView(
          slivers: [
            SliverSafeArea(
              minimum: const EdgeInsets.all(6),
              sliver: SliverList.list(children: _buildPreviewContent()),
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

  List<Widget> _buildPreviewContent() {
    final List<Widget> content = [];
    final headers = _call.response!.headers;
    final contentType = getContentType(headers);
    final bodyContent = formatBody(_call.response!.body, contentType);

    // Enhanced JSON detection and display
    final isJsonByContentType = contentType != null && contentType.toLowerCase().contains('json');
    final isJsonByStructure = _isValidJsonContent(bodyContent);

    if (isJsonByContentType || isJsonByStructure) {
      try {
        final dynamic jsonData = jsonDecode(bodyContent);
        // Use JsonViewer for interactive JSON display
        content.add(const SizedBox(height: 8));
        content.add(JsonViewer(jsonData));
      } catch (e) {
        // If JSON parsing fails, show as text with error message
        content.add(getListRow("JSON Parse Error:", "Failed to parse JSON: $e"));
        content.add(const SizedBox(height: 8));
        content.add(
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: SelectableText(bodyContent),
          ),
        );
      }
    } else {
      // For non-JSON content, show as formatted text
      content.add(const SizedBox(height: 8));
      content.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: SelectableText(bodyContent),
        ),
      );
    }

    return content;
  }

  /// Check if content appears to be valid JSON
  bool _isValidJsonContent(String content) {
    if (content.isEmpty) return false;

    // Check for JSON-like structure
    final trimmedContent = content.trim();
    if (!trimmedContent.startsWith('{') || !trimmedContent.endsWith('}')) {
      if (!trimmedContent.startsWith('[') || !trimmedContent.endsWith(']')) {
        return false;
      }
    }

    // Additional checks for valid JSON structure
    return trimmedContent.contains('{') && trimmedContent.contains('}') ||
        trimmedContent.contains('[') && trimmedContent.contains(']');
  }

  @override
  void dispose() {
    super.dispose();
  }
}
