import 'dart:convert';

import 'package:chuck_interceptor/model/chuck_http_call.dart';
import 'package:chuck_interceptor/model/chuck_http_response.dart';
import 'package:chuck_interceptor/ui/widget/chuck_json_viewer.dart';
import 'package:chuck_interceptor/utils/chuck_constants.dart';
import 'package:chuck_interceptor/ui/widget/chuck_base_call_details_widget.dart';
import 'package:flutter/material.dart';

class ChuckCallResponsePreviewWidget extends StatefulWidget {
  const ChuckCallResponsePreviewWidget(this.call, {super.key});

  final ChuckHttpCall call;

  @override
  State<StatefulWidget> createState() => _ChuckCallResponseWidgetState();
}

class _ChuckCallResponseWidgetState extends ChuckBaseCallDetailsWidgetState<ChuckCallResponsePreviewWidget> {
  static const _imageContentType = "image";
  static const _jsonContentType = "json";
  static const _xmlContentType = "xml";
  static const _textContentType = "text";

  static const _kLargeOutputSize = 100000;
  bool _showLargeBody = false;
  bool _showUnsupportedBody = false;

  final ScrollController _scrollController = ScrollController();
  ChuckHttpResponse? _parsedResponse;
  String _bodyContent = '';
  bool _isJson = false;
  Object? _jsonData;

  ChuckHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    if (!_call.loading && _call.response != null) {
      return Scrollbar(
        controller: _scrollController,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverSafeArea(minimum: const EdgeInsets.all(6), sliver: _buildBodySliver()),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [CircularProgressIndicator(), Text("Awaiting response...")],
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildBodySliver() {
    if (_isImageResponse()) {
      return SliverList.list(children: _buildImageBodyRows());
    } else if (_isTextResponse()) {
      if (_isLargeResponseBody() && !_showLargeBody) {
        return SliverList.list(children: _buildLargeBodyTextRows());
      }
      return _buildTextBodySliver();
    }
    return SliverList.list(children: _buildUnknownBodyRows());
  }

  List<Widget> _buildImageBodyRows() {
    final List<Widget> rows = [];
    rows.add(
      Column(
        children: [
          Row(
            children: const [Text("Body: Image", style: TextStyle(fontWeight: FontWeight.bold))],
          ),
          const SizedBox(height: 8),
          Image.network(
            _call.uri,
            fit: BoxFit.fill,
            headers: _buildRequestHeaders(),
            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
    return rows;
  }

  List<Widget> _buildLargeBodyTextRows() {
    return [
      getListRow("Body:", "Too large to show (${_call.response!.body.toString().length} Bytes)"),
      const SizedBox(height: 8),
      ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(ChuckConstants.lightRed),
          foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
        ),
        onPressed: () {
          setState(() {
            _showLargeBody = true;
          });
        },
        child: const Text("Show body"),
      ),
      const SizedBox(height: 8),
      const Text("Warning! It will take some time to render output."),
    ];
  }

  Widget _buildTextBodySliver() {
    _parseResponse(_call.response!);
    if (_isJson) {
      // Lazy, interactive JSON tree: only rows on screen are built
      return SliverJsonViewer(_jsonData);
    }
    return SliverToBoxAdapter(child: getListRow("Body:", _bodyContent));
  }

  /// Formats and decodes the body once per response instead of on every rebuild.
  void _parseResponse(ChuckHttpResponse response) {
    if (identical(_parsedResponse, response)) {
      return;
    }
    _parsedResponse = response;
    final contentType = getContentType(response.headers);
    _bodyContent = formatBody(response.body, contentType);
    _jsonData = null;
    _isJson = false;
    final trimmed = _bodyContent.trim();
    final looksLikeJson =
        (trimmed.startsWith('{') && trimmed.endsWith('}')) || (trimmed.startsWith('[') && trimmed.endsWith(']'));
    if (looksLikeJson || (contentType?.toLowerCase().contains(_jsonContentType) ?? false)) {
      try {
        _jsonData = jsonDecode(_bodyContent);
        _isJson = true;
      } on FormatException {
        // Not valid JSON, fall back to plain text
      }
    }
  }

  List<Widget> _buildUnknownBodyRows() {
    final List<Widget> rows = [];
    final headers = _call.response!.headers;
    final contentType = getContentType(headers) ?? "<unknown>";
    if (_showUnsupportedBody) {
      final bodyContent = formatBody(_call.response!.body, getContentType(headers));
      rows.add(getListRow("Body:", bodyContent));
    } else {
      rows.add(
        getListRow(
          "Body:",
          "Unsupported body. Chuck can render video/image/text body. "
              "Response has Content-Type: $contentType which can't be handled. "
              "If you're feeling lucky you can try button below to try render body"
              " as text, but it may fail.",
        ),
      );
      rows.add(
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(ChuckConstants.lightRed),
            foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
          ),
          onPressed: () {
            setState(() {
              _showUnsupportedBody = true;
            });
          },
          child: const Text("Show unsupported body"),
        ),
      );
    }
    return rows;
  }

  Map<String, String> _buildRequestHeaders() {
    final Map<String, String> requestHeaders = {};
    if (_call.request?.headers != null) {
      requestHeaders.addAll(
        _call.request!.headers.map((String key, dynamic value) {
          return MapEntry(key, value.toString());
        }),
      );
    }
    return requestHeaders;
  }

  bool _isImageResponse() {
    return _getContentTypeOfResponse()!.toLowerCase().contains(_imageContentType);
  }

  bool _isTextResponse() {
    final String responseContentTypeLowerCase = _getContentTypeOfResponse()!.toLowerCase();

    return responseContentTypeLowerCase.contains(_jsonContentType) ||
        responseContentTypeLowerCase.contains(_xmlContentType) ||
        responseContentTypeLowerCase.contains(_textContentType);
  }

  String? _getContentTypeOfResponse() {
    return getContentType(_call.response!.headers);
  }

  bool _isLargeResponseBody() {
    return _call.response!.body != null && _call.response!.body.toString().length > _kLargeOutputSize;
  }
}
