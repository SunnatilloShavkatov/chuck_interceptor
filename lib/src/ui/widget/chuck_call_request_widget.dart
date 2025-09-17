import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_base_call_details_widget.dart';
import 'package:flutter/material.dart';

class ChuckCallRequestWidget extends StatefulWidget {
  final ChuckHttpCall call;

  const ChuckCallRequestWidget(this.call, {super.key});

  @override
  State<StatefulWidget> createState() => _ChuckCallRequestWidget();
}

class _ChuckCallRequestWidget extends ChuckBaseCallDetailsWidgetState<ChuckCallRequestWidget> {
  ChuckHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [];
    rows.add(getListRow("Started:", _call.request!.time.toString()));
    rows.add(getListRow("Bytes sent:", formatBytes(_call.request!.size)));
    rows.add(getListRow("Content type:", getContentType(_call.request!.headers)!));

    final dynamic body = _call.request!.body;
    var bodyContent = "Body is empty";
    if (body != null) {
      bodyContent = formatBody(body, getContentType(_call.request!.headers));
    }
    rows.add(getListRow("Body:", bodyContent));
    final formDataFields = _call.request!.formDataFields;
    if (formDataFields?.isNotEmpty == true) {
      rows.add(getListRow("Form data fields: ", ""));
      formDataFields!.forEach((field) {
        rows.add(getListRow("   • ${field.name}:", field.value));
      });
    }
    final formDataFiles = _call.request!.formDataFiles;
    if (formDataFiles?.isNotEmpty == true) {
      rows.add(getListRow("Form data files: ", ""));
      formDataFiles!.forEach((field) {
        rows.add(getListRow("   • ${field.fileName}:", "${field.contentType} / ${field.length} B"));
      });
    }

    final queryParameters = _call.request!.queryParameters;
    var queryParametersContent = "Query parameters are empty";
    if (queryParameters.isNotEmpty) {
      queryParametersContent = "";
    }
    rows.add(getListRow("Query Parameters: ", queryParametersContent));
    _call.request!.queryParameters.forEach((query, dynamic value) {
      rows.add(getListRow("   • $query:", value.toString()));
    });

    final headers = _call.request!.headers;
    var headersContent = "Headers are empty";
    if (headers.isNotEmpty) {
      headersContent = "";
    }
    rows.add(getListRow("Headers: ", headersContent));

    final sortedHeaders = Map<String, dynamic>.from(headers);
    dynamic xTokenValue;
    if (sortedHeaders.containsKey('X-Token')) {
      xTokenValue = sortedHeaders.remove('X-Token');
    }

    sortedHeaders.forEach((header, dynamic value) {
      rows.add(getListRow("   • $header:", value.toString()));
    });

    if (xTokenValue != null) {
      rows.add(getListRow("   • X-Token:", xTokenValue.toString()));
    }

    return CustomScrollView(
      slivers: [
        SliverSafeArea(
          minimum: const EdgeInsets.all(6),
          sliver: SliverList.list(children: rows),
        ),
      ],
    );
  }
}
