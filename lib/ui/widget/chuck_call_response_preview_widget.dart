import 'dart:convert';

import 'package:chuck_interceptor/model/chuck_http_call.dart';
import 'package:chuck_interceptor/ui/widget/chuck_json_viewer.dart';
import 'package:chuck_interceptor/utils/chuck_constants.dart';
import 'package:chuck_interceptor/ui/widget/chuck_base_call_details_widget.dart';
import 'package:flutter/material.dart';

class ChuckCallResponsePreviewWidget extends StatefulWidget {
  final ChuckHttpCall call;

  const ChuckCallResponsePreviewWidget(this.call);

  @override
  State<StatefulWidget> createState() {
    return _ChuckCallResponseWidgetState();
  }
}

class _ChuckCallResponseWidgetState
    extends ChuckBaseCallDetailsWidgetState<ChuckCallResponsePreviewWidget> {
  static const _imageContentType = "image";
  static const _jsonContentType = "json";
  static const _xmlContentType = "xml";
  static const _textContentType = "text";

  static const _kLargeOutputSize = 100000;
  bool _showLargeBody = false;
  bool _showUnsupportedBody = false;

  ChuckHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [];
    if (!_call.loading) {
      rows.addAll(_buildBodyRows());

      return Container(
        padding: const EdgeInsets.all(6),
        child: ListView(children: rows),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            Text("Awaiting response...")
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<Widget> _buildBodyRows() {
    final List<Widget> rows = [];
    if (_isImageResponse()) {
      rows.addAll(_buildImageBodyRows());
    } else if (_isTextResponse()) {
      if (_isLargeResponseBody()) {
        rows.addAll(_buildLargeBodyTextRows());
      } else {
        rows.addAll(_buildTextBodyRows());
      }
    } else {
      rows.addAll(_buildUnknownBodyRows());
    }

    return rows;
  }

  List<Widget> _buildImageBodyRows() {
    final List<Widget> rows = [];
    rows.add(
      Column(
        children: [
          Row(
            children: const [
              Text(
                "Body: Image",
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            ],
          ),
          const SizedBox(height: 8),
          Image.network(
            _call.uri,
            fit: BoxFit.fill,
            headers: _buildRequestHeaders(),
            loadingBuilder: (BuildContext context, Widget child,
                ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
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
    final List<Widget> rows = [];
    if (_showLargeBody) {
      return _buildTextBodyRows();
    } else {
      rows.add(getListRow("Body:",
          "Too large to show (${_call.response!.body.toString().length} Bytes)"));
      rows.add(const SizedBox(height: 8));
      rows.add(
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor:
                MaterialStateProperty.all<Color>(ChuckConstants.lightRed),
          ),
          onPressed: () {
            setState(() {
              _showLargeBody = true;
            });
          },
          child: const Text("Show body"),
        ),
      );
      rows.add(const SizedBox(height: 8));
      rows.add(const Text("Warning! It will take some time to render output."));
    }
    return rows;
  }

  List<Widget> _buildTextBodyRows() {
    final List<Widget> rows = [];
    final headers = _call.response!.headers;
    final bodyContent =
        formatBody(_call.response!.body, getContentType(headers));
    //rows.add(getListRow("Body:", bodyContent));
    if (bodyContent.contains("{") && bodyContent.contains("}")) {
      rows.add(JsonViewer(jsonDecode(bodyContent)));
    } else {
      rows.add(getListRow("Body:", bodyContent));
    }

    return rows;
  }

  List<Widget> _buildUnknownBodyRows() {
    final List<Widget> rows = [];
    final headers = _call.response!.headers;
    final contentType = getContentType(headers) ?? "<unknown>";

    if (_showUnsupportedBody) {
      final bodyContent =
          formatBody(_call.response!.body, getContentType(headers));
      rows.add(getListRow("Body:", bodyContent));
    } else {
      rows.add(getListRow(
          "Body:",
          "Unsupported body. Chuck can render video/image/text body. "
              "Response has Content-Type: $contentType which can't be handled. "
              "If you're feeling lucky you can try button below to try render body"
              " as text, but it may fail."));
      rows.add(
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor:
                MaterialStateProperty.all<Color>(ChuckConstants.lightRed),
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
        _call.request!.headers.map(
          (String key, dynamic value) {
            return MapEntry(key, value.toString());
          },
        ),
      );
    }
    return requestHeaders;
  }

  bool _isImageResponse() {
    return _getContentTypeOfResponse()!
        .toLowerCase()
        .contains(_imageContentType);
  }

  bool _isTextResponse() {
    final String responseContentTypeLowerCase =
        _getContentTypeOfResponse()!.toLowerCase();

    return responseContentTypeLowerCase.contains(_jsonContentType) ||
        responseContentTypeLowerCase.contains(_xmlContentType) ||
        responseContentTypeLowerCase.contains(_textContentType);
  }

  String? _getContentTypeOfResponse() {
    return getContentType(_call.response!.headers);
  }

  bool _isLargeResponseBody() {
    return _call.response!.body != null &&
        _call.response!.body.toString().length > _kLargeOutputSize;
  }
}
