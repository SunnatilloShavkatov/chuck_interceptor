// ignore_for_file: discarded_futures, avoid_dynamic_calls

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JsonViewer extends StatefulWidget {
  const JsonViewer(this.jsonObj, {super.key});

  final dynamic jsonObj;

  @override
  State<JsonViewer> createState() => _JsonViewerState();
}

class _JsonViewerState extends State<JsonViewer> {
  @override
  Widget build(BuildContext context) => getContentWidget(widget.jsonObj);

  static Widget getContentWidget(Object? content) {
    if (content == null) {
      return SelectableText(
        '{}',
        contextMenuBuilder: (_, editableTextState) => AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: editableTextState.contextMenuButtonItems,
        ),
      );
    } else if (content is List) {
      return JsonArrayViewer(content);
    } else if (content is Map<String, dynamic>) {
      return JsonObjectViewer(content);
    }
    return const SizedBox.shrink();
  }
}

class JsonObjectViewer extends StatefulWidget {
  const JsonObjectViewer(this.jsonObj, {super.key, this.notRoot = false});

  final Map<String, dynamic> jsonObj;
  final bool notRoot;

  @override
  JsonObjectViewerState createState() => JsonObjectViewerState();
}

class JsonObjectViewerState extends State<JsonObjectViewer> {
  Map<String, bool> openFlag = {};

  @override
  Widget build(BuildContext context) {
    if (widget.notRoot) {
      return Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _getList()),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: _getList());
  }

  List<Widget> _getList() {
    final List<Widget> list = [];
    for (final MapEntry<String, dynamic> entry in widget.jsonObj.entries) {
      final bool ex = isExtensible(entry.value);
      final bool ink = isInkWell(entry.value);
      list
        ..add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (ex)
                (openFlag[entry.key] ?? false)
                    ? InkWell(
                        onTap: () {
                          setState(() {
                            openFlag[entry.key] = !(openFlag[entry.key] ?? false);
                          });
                        },
                        child: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                      )
                    : InkWell(
                        onTap: () {
                          setState(() {
                            openFlag[entry.key] = !(openFlag[entry.key] ?? false);
                          });
                        },
                        child: Icon(Icons.arrow_right, color: Colors.grey[700]),
                      )
              else
                const SizedBox.shrink(),
              if (ex && ink)
                SelectableText(
                  entry.key,
                  contextMenuBuilder: (_, editableTextState) => AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: editableTextState.contextMenuAnchors,
                    buttonItems: editableTextState.contextMenuButtonItems,
                  ),
                )
              else
                SelectableText(
                  entry.key,
                  style: TextStyle(color: entry.value == null ? Colors.grey : null),
                  contextMenuBuilder: (_, editableTextState) => AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: editableTextState.contextMenuAnchors,
                    buttonItems: editableTextState.contextMenuButtonItems,
                  ),
                ),
              const Text(':', style: TextStyle(color: Colors.grey)),
              const Padding(padding: EdgeInsets.only(left: 3)),
              getValueWidget(entry),
            ],
          ),
        )
        ..add(const Padding(padding: EdgeInsets.only(top: 4)));
      if (openFlag[entry.key] ?? false) {
        list.add(getContentWidget(entry.value));
      }
    }
    return list;
  }

  static Widget getContentWidget(Object? content) {
    if (content is List) {
      return JsonArrayViewer(content, notRoot: true);
    } else if (content is Map<String, dynamic>) {
      return JsonObjectViewer(content, notRoot: true);
    }
    return const SizedBox.shrink();
  }

  static bool isInkWell(Object? content) {
    if (content == null) {
      return false;
    } else if (content is int) {
      return false;
    } else if (content is String) {
      return false;
    } else if (content is bool) {
      return false;
    } else if (content is double) {
      return false;
    } else if (content is List) {
      if (content.isEmpty) {
        return false;
      } else {
        return true;
      }
    }
    return true;
  }

  Widget getValueWidget(MapEntry<String, dynamic> entry) {
    if (entry.value == null) {
      return Expanded(
        child: SelectableText(
          'undefined',
          style: const TextStyle(color: Colors.grey),
          contextMenuBuilder: (_, editableTextState) => AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: editableTextState.contextMenuButtonItems,
          ),
        ),
      );
    } else if (entry.value is int) {
      return Expanded(
        child: SelectableText(
          entry.value.toString(),
          style: const TextStyle(color: Color(0xff6491b3)),
          contextMenuBuilder: (_, editableTextState) => AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: editableTextState.contextMenuButtonItems,
          ),
        ),
      );
    } else if (entry.value is String) {
      return Expanded(
        child: SelectableText(
          '"${entry.value}"',
          style: const TextStyle(color: Color(0xff6a8759)),
          contextMenuBuilder: (_, editableTextState) => AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: editableTextState.contextMenuButtonItems,
          ),
        ),
      );
    } else if (entry.value is bool) {
      return Expanded(
        child: SelectableText(
          entry.value.toString(),
          style: const TextStyle(color: Color(0xffca7832)),
          contextMenuBuilder: (_, editableTextState) => AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: editableTextState.contextMenuButtonItems,
          ),
        ),
      );
    } else if (entry.value is double) {
      return Expanded(
        child: SelectableText(
          entry.value.toString(),
          style: const TextStyle(color: Color(0xff6491b3)),
          contextMenuBuilder: (_, editableTextState) => AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: editableTextState.contextMenuButtonItems,
          ),
        ),
      );
    } else if (entry.value is List) {
      if ((entry.value as List).isEmpty) {
        return InkWell(
          onTap: () {
            setState(() {
              openFlag[entry.key] = !(openFlag[entry.key] ?? false);
            });
          },
          onDoubleTap: () {
            Clipboard.setData(ClipboardData(text: jsonEncode(entry.value))).then((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const CustomSnackBar());
              }
            });
          },
          child: const Text('Array[0]', style: TextStyle(color: Colors.grey)),
        );
      } else {
        return InkWell(
          onTap: () {
            setState(() {
              openFlag[entry.key] = !(openFlag[entry.key] ?? false);
            });
          },
          onDoubleTap: () {
            Clipboard.setData(ClipboardData(text: jsonEncode(entry.value))).then((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const CustomSnackBar());
              }
            });
          },
          child: Text(
            'Array<${getTypeName(entry.value[0])}>[${entry.value.length}]',
            style: const TextStyle(color: Colors.grey),
          ),
        );
      }
    }
    return InkWell(
      onTap: () {
        setState(() {
          openFlag[entry.key] = !(openFlag[entry.key] ?? false);
        });
      },
      onDoubleTap: () {
        Clipboard.setData(ClipboardData(text: jsonEncode(entry.value))).then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const CustomSnackBar());
          }
        });
      },
      child: const Text('Object', style: TextStyle(color: Colors.grey)),
    );
  }

  static bool isExtensible(Object? content) {
    if (content == null) {
      return false;
    } else if (content is int) {
      return false;
    } else if (content is String) {
      return false;
    } else if (content is bool) {
      return false;
    } else if (content is double) {
      return false;
    }
    return true;
  }

  static String getTypeName(Object? content) {
    if (content is int) {
      return 'int';
    } else if (content is String) {
      return 'String';
    } else if (content is bool) {
      return 'bool';
    } else if (content is double) {
      return 'double';
    } else if (content is List) {
      return 'List';
    }
    return 'Object';
  }
}

class JsonArrayViewer extends StatefulWidget {
  const JsonArrayViewer(this.jsonArray, {super.key, this.notRoot = false});

  final List<dynamic> jsonArray;

  final bool notRoot;

  @override
  State<JsonArrayViewer> createState() => _JsonArrayViewerState();
}

class _JsonArrayViewerState extends State<JsonArrayViewer> {
  late List<bool> openFlag;

  @override
  Widget build(BuildContext context) {
    if (widget.notRoot) {
      return Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _getList()),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: _getList());
  }

  @override
  void initState() {
    super.initState();
    openFlag = List.filled(widget.jsonArray.length, false);
  }

  List<Widget> _getList() {
    final List<Widget> list = [];
    for (int i = 0; i < widget.jsonArray.length; i++) {
      final content = widget.jsonArray[i];
      final bool ex = JsonObjectViewerState.isExtensible(content);
      final bool ink = JsonObjectViewerState.isInkWell(content);
      list
        ..add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (ex)
                (openFlag[i])
                    ? InkWell(
                        onTap: () {
                          setState(() {
                            openFlag[i] = !openFlag[i];
                          });
                        },
                        child: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                      )
                    : InkWell(
                        onTap: () {
                          setState(() {
                            openFlag[i] = !openFlag[i];
                          });
                        },
                        child: Icon(Icons.arrow_right, color: Colors.grey[700]),
                      )
              else
                InkWell(
                  onTap: () {
                    setState(() {
                      openFlag[i] = !openFlag[i];
                    });
                  },
                  child: const Icon(Icons.arrow_right, color: Color.fromARGB(0, 0, 0, 0)),
                ),
              if (ex && ink)
                Text('[$i]')
              else
                Text('[$i]', style: TextStyle(color: content == null ? Colors.grey : Colors.black)),
              const Text(':', style: TextStyle(color: Colors.grey)),
              const Padding(padding: EdgeInsets.only(left: 3)),
              getValueWidget(content, i),
            ],
          ),
        )
        ..add(const Padding(padding: EdgeInsets.only(top: 4)));
      if (openFlag[i]) {
        list.add(JsonObjectViewerState.getContentWidget(content));
      }
    }
    return list;
  }

  Widget getValueWidget(Object? content, int index) {
    if (content == null) {
      return Expanded(
        child: SelectableText(
          'undefined',
          style: const TextStyle(color: Colors.grey),
          contextMenuBuilder: (_, editableTextState) => AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: editableTextState.contextMenuButtonItems,
          ),
        ),
      );
    } else if (content is int) {
      return Expanded(
        child: SelectableText(
          content.toString(),
          style: const TextStyle(color: Color(0xff6491b3)),
          contextMenuBuilder: (_, editableTextState) => AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: editableTextState.contextMenuButtonItems,
          ),
        ),
      );
    } else if (content is String) {
      return Expanded(
        child: SelectableText(
          '"$content"',
          style: const TextStyle(color: Color(0xff6a8759)),
          contextMenuBuilder: (_, editableTextState) => AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: editableTextState.contextMenuButtonItems,
          ),
        ),
      );
    } else if (content is bool) {
      return Expanded(
        child: SelectableText(
          content.toString(),
          style: const TextStyle(color: Color(0xffca7832)),
          contextMenuBuilder: (_, editableTextState) => AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: editableTextState.contextMenuButtonItems,
          ),
        ),
      );
    } else if (content is double) {
      return Expanded(
        child: SelectableText(
          content.toString(),
          style: const TextStyle(color: Color(0xff6491b3)),
          contextMenuBuilder: (_, editableTextState) => AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: editableTextState.contextMenuButtonItems,
          ),
        ),
      );
    } else if (content is List) {
      if (content.isEmpty) {
        return InkWell(
          onTap: () {
            setState(() {
              openFlag[index] = !openFlag[index];
            });
          },
          onDoubleTap: () {
            Clipboard.setData(ClipboardData(text: jsonEncode(content))).then((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const CustomSnackBar());
              }
            });
          },
          child: const Text('Array[0]', style: TextStyle(color: Colors.grey)),
        );
      } else {
        return InkWell(
          onTap: () {
            setState(() {
              openFlag[index] = !openFlag[index];
            });
          },
          onDoubleTap: () {
            Clipboard.setData(ClipboardData(text: jsonEncode(content))).then((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const CustomSnackBar());
              }
            });
          },
          child: Text(
            'Array<${JsonObjectViewerState.getTypeName(content)}>[${content.length}]',
            style: const TextStyle(color: Colors.grey),
          ),
        );
      }
    }
    return InkWell(
      onTap: () {
        setState(() {
          openFlag[index] = !openFlag[index];
        });
      },
      onDoubleTap: () {
        Clipboard.setData(ClipboardData(text: jsonEncode(content))).then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const CustomSnackBar());
          }
        });
      },
      child: const Text('Object', style: TextStyle(color: Colors.grey)),
    );
  }
}

class CustomSnackBar extends SnackBar {
  const CustomSnackBar({
    super.key,
    super.backgroundColor = Colors.yellow,
    super.content = const Text('Copied to your clipboard !', style: TextStyle(color: Colors.black)),
  });

  Widget build(BuildContext context) => SnackBar(backgroundColor: backgroundColor, content: content);
}
