import 'dart:convert' show jsonDecode;

import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/model/chuck_http_response.dart';
import 'package:chuck_interceptor/src/theme/chuck_theme.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_base_call_details_widget.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_json_viewer.dart';
import 'package:material_ui/material_ui.dart';

class ChuckCallResponsePreviewWidget extends StatefulWidget {
  const new(this.call, {super.key});

  final ChuckHttpCall call;

  @override
  State<StatefulWidget> createState() => _ChuckCallResponsePreviewWidgetState();
}

class _ChuckCallResponsePreviewWidgetState extends ChuckBaseCallDetailsWidgetState<ChuckCallResponsePreviewWidget> {
  final ScrollController _scrollController = ScrollController();

  ChuckHttpResponse? _parsedResponse;
  String _bodyContent = '';
  bool _isJson = false;
  Object? _jsonData;
  Object? _jsonError;

  ChuckHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    if (!_call.loading && _call.response != null) {
      final double bottomPadding = MediaQuery.paddingOf(context).bottom + 84;
      return Scrollbar(
        controller: _scrollController,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverSafeArea(
              minimum: EdgeInsets.only(left: 6, top: 6, right: 6, bottom: bottomPadding),
              sliver: _buildPreviewSliver(),
            ),
          ],
        ),
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Awaiting response...')],
        ),
      );
    }
  }

  Widget _buildPreviewSliver() {
    _parseResponse(_call.response!);

    if (_jsonError != null) {
      // If JSON parsing fails, show as text with error message
      return SliverList.list(
        children: [
          getListRow('JSON Parse Error:', 'Failed to parse JSON: $_jsonError'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.chuckTheme.errorPreviewBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.chuckTheme.errorPreviewBorder),
            ),
            child: SelectableText(_bodyContent),
          ),
        ],
      );
    }
    if (_isJson) {
      // Lazy, interactive JSON tree: only rows on screen are built
      return SliverPadding(padding: const EdgeInsets.only(top: 8), sliver: SliverJsonViewer(_jsonData));
    }
    // For non-JSON content, show as formatted text
    return SliverToBoxAdapter(
      child: Padding(padding: const EdgeInsets.fromLTRB(8, 16, 8, 8), child: SelectableText(_bodyContent)),
    );
  }

  /// Formats and decodes the body once per response instead of on every rebuild.
  void _parseResponse(ChuckHttpResponse response) {
    if (identical(_parsedResponse, response)) {
      return;
    }
    _parsedResponse = response;
    _jsonData = null;
    _jsonError = null;

    final contentType = getContentType(response.headers);
    _bodyContent = formatBody(response.body, contentType);

    // Enhanced JSON detection and display
    final isJsonByContentType = contentType != null && contentType.toLowerCase().contains('json');
    _isJson = isJsonByContentType || _isValidJsonContent(_bodyContent);
    if (_isJson) {
      try {
        _jsonData = jsonDecode(_bodyContent);
      } catch (e) {
        _jsonError = e;
      }
    }
  }

  /// Check if content appears to be valid JSON
  bool _isValidJsonContent(String content) {
    if (content.isEmpty) {
      return false;
    }

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
    _scrollController.dispose();
    super.dispose();
  }
}
