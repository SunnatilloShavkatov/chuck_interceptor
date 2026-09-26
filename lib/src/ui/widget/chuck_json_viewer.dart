import 'dart:collection' show HashSet;
import 'dart:convert' show jsonEncode;

import 'package:chuck_interceptor/src/helper/chuck_snack_bar_helper.dart';
import 'package:chuck_interceptor/src/theme/chuck_theme.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:material_ui/material_ui.dart';

/// Interactive JSON tree rendered as a lazy sliver.
///
/// The tree is flattened into the rows that are currently visible (children of
/// collapsed nodes are skipped) and handed to [SliverList.builder], so only the
/// rows on screen are built no matter how large the response is.
class SliverJsonViewer extends StatefulWidget {
  const new(this.json, {super.key});

  final Object? json;

  @override
  State<SliverJsonViewer> createState() => _SliverJsonViewerState();
}

class _SliverJsonViewerState extends State<SliverJsonViewer> {
  static const double _indent = 14;
  static const double _arrowSize = 24;

  /// Expanded containers, tracked by identity: every map/list produced by
  /// `jsonDecode` is a distinct object, so no path bookkeeping is needed.
  final Set<Object> _expanded = HashSet.identity();
  List<_JsonRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    _rows = _flatten();
  }

  @override
  void didUpdateWidget(SliverJsonViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.json, widget.json)) {
      _expanded.clear();
      _rows = _flatten();
    }
  }

  List<_JsonRow> _flatten() {
    final List<_JsonRow> rows = [];
    void visit(Object? container, int depth) {
      if (container is Map) {
        for (final MapEntry<Object?, Object?> entry in container.entries) {
          rows.add(_JsonRow(entry.key.toString(), entry.value, depth, isIndex: false));
          if (_isExpanded(entry.value)) {
            visit(entry.value, depth + 1);
          }
        }
      } else if (container is List) {
        for (int i = 0; i < container.length; i++) {
          rows.add(_JsonRow('[$i]', container[i], depth, isIndex: true));
          if (_isExpanded(container[i])) {
            visit(container[i], depth + 1);
          }
        }
      }
    }

    visit(widget.json, 0);
    return rows;
  }

  bool _isExpanded(Object? value) => value != null && _expanded.contains(value);

  void _toggle(Object value) {
    setState(() {
      if (!_expanded.remove(value)) {
        _expanded.add(value);
      }
      _rows = _flatten();
    });
  }

  Future<void> _copy(Object value) async {
    await Clipboard.setData(ClipboardData(text: jsonEncode(value)));
    if (mounted) {
      ChuckSnackBarHelper.show(context, 'Copied to clipboard!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Object? json = widget.json;
    if (json == null) {
      return SliverToBoxAdapter(child: _selectable('{}'));
    }
    if (json is! Map && json is! List) {
      return SliverToBoxAdapter(child: Row(children: [_buildValue(context, json)]));
    }
    return SliverList.builder(
      itemCount: _rows.length,
      itemBuilder: (context, index) => _buildRow(context, _rows[index]),
    );
  }

  Widget _buildRow(BuildContext context, _JsonRow row) {
    final theme = context.chuckTheme;
    final Object? value = row.value;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: row.depth * _indent, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (value is Map || value is List)
            InkWell(
              onTap: () => _toggle(value!),
              child: Icon(
                _expanded.contains(value) ? Icons.arrow_drop_down : Icons.arrow_right,
                size: _arrowSize,
                color: theme.secondaryText,
              ),
            )
          else if (row.isIndex)
            // Keeps primitive array items aligned with expandable siblings.
            const SizedBox(width: _arrowSize),
          if (row.isIndex)
            Text(row.label, style: TextStyle(color: value == null ? theme.neutral : theme.primaryText))
          else
            _selectable(
              row.label,
              style: TextStyle(
                color: value == null ? theme.jsonNullColor : theme.jsonKeyColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          Text(':', style: TextStyle(color: theme.neutral)),
          const SizedBox(width: 3),
          _buildValue(context, value),
        ],
      ),
    );
  }

  Widget _buildValue(BuildContext context, Object? value) {
    final theme = context.chuckTheme;
    return switch (value) {
      null => Expanded(
        child: _selectable(
          'null',
          style: TextStyle(color: theme.jsonNullColor, fontStyle: FontStyle.italic),
        ),
      ),
      num() => Expanded(
        child: _selectable(value.toString(), style: TextStyle(color: theme.jsonNumberColor)),
      ),
      String() => Expanded(
        child: _selectable('"$value"', style: TextStyle(color: theme.jsonStringColor)),
      ),
      bool() => Expanded(
        child: _selectable(
          value.toString(),
          style: TextStyle(color: theme.jsonBooleanColor, fontWeight: FontWeight.bold),
        ),
      ),
      List() || Map() => InkWell(
        onTap: () => _toggle(value),
        onDoubleTap: () => _copy(value),
        child: Text(_describeContainer(value), style: TextStyle(color: theme.neutral)),
      ),
      _ => Expanded(child: _selectable(value.toString())),
    };
  }

  static String _describeContainer(Object value) {
    if (value is List) {
      return value.isEmpty ? 'Array[0]' : 'Array<${_typeName(value.first)}>[${value.length}]';
    }
    return 'Object';
  }

  static String _typeName(Object? value) => switch (value) {
    int() => 'int',
    double() => 'double',
    String() => 'String',
    bool() => 'bool',
    List() => 'List',
    _ => 'Object',
  };

  static Widget _selectable(String text, {TextStyle? style}) =>
      SelectableText(text, style: style, contextMenuBuilder: _contextMenuBuilder);

  static Widget _contextMenuBuilder(BuildContext context, EditableTextState editableTextState) =>
      AdaptiveTextSelectionToolbar.buttonItems(
        anchors: editableTextState.contextMenuAnchors,
        buttonItems: editableTextState.contextMenuButtonItems,
      );
}

/// One visible line of the flattened JSON tree.
final class _JsonRow {
  const new(this.label, this.value, this.depth, {required this.isIndex});

  final String label;
  final Object? value;
  final int depth;
  final bool isIndex;
}
