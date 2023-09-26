library flutter_json_widget;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JsonViewer extends StatefulWidget {
  final dynamic jsonObj;

  const JsonViewer(this.jsonObj, {super.key});

  @override
  _JsonViewerState createState() => _JsonViewerState();
}

class _JsonViewerState extends State<JsonViewer> {
  @override
  Widget build(BuildContext context) {
    return getContentWidget(widget.jsonObj);
  }

  static getContentWidget(dynamic content) {
    if (content == null) {
      return const SelectableText('{}');
    } else if (content is List) {
      return JsonArrayViewer(content, notRoot: false);
    } else {
      return JsonObjectViewer(content, notRoot: false);
    }
  }
}

class JsonObjectViewer extends StatefulWidget {
  final Map<String, dynamic> jsonObj;
  final bool notRoot;

  JsonObjectViewer(this.jsonObj, {super.key, this.notRoot = false});

  @override
  JsonObjectViewerState createState() => JsonObjectViewerState();
}

class JsonObjectViewerState extends State<JsonObjectViewer> {
  Map<String, bool> openFlag = {};

  @override
  Widget build(BuildContext context) {
    if (widget.notRoot) {
      return Container(
        padding: const EdgeInsets.only(left: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _getList(),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _getList(),
    );
  }

  _getList() {
    List<Widget> list = [];
    for (MapEntry<String, dynamic> entry in widget.jsonObj.entries) {
      bool ex = isExtensible(entry.value);
      bool ink = isInkWell(entry.value);
      list.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ex
                ? (openFlag[entry.key] ?? false)
                    ? InkWell(
                        onTap: () {
                          setState(() {
                            openFlag[entry.key] =
                                !(openFlag[entry.key] ?? false);
                          });
                        },
                        child: Icon(
                          Icons.arrow_drop_down,
                          size: 14,
                          color: Colors.grey[700],
                        ),
                      )
                    : InkWell(
                        onTap: () {
                          setState(() {
                            openFlag[entry.key] =
                                !(openFlag[entry.key] ?? false);
                          });
                        },
                        child: Icon(
                          Icons.arrow_right,
                          size: 14,
                          color: Colors.grey[700],
                        ),
                      )
                : InkWell(
                    onTap: () {
                      setState(() {
                        openFlag[entry.key] = !(openFlag[entry.key] ?? false);
                      });
                    },
                    child: const Icon(
                      Icons.arrow_right,
                      color: Color.fromARGB(0, 0, 0, 0),
                      size: 14,
                    ),
                  ),
            (ex && ink)
                ? SelectableText(
                    entry.key,
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  )
                : SelectableText(
                    entry.key,
                    style: TextStyle(
                      color: entry.value == null ? Colors.grey : Colors.black,
                    ),
                  ),
            const Text(
              ':',
              style: TextStyle(color: Colors.grey),
            ),
            Padding(padding: EdgeInsets.only(left: 3)),
            getValueWidget(entry)
          ],
        ),
      );
      list.add(Padding(padding: EdgeInsets.only(top: 4)));
      if (openFlag[entry.key] ?? false) {
        list.add(getContentWidget(entry.value));
      }
    }
    return list;
  }

  static getContentWidget(dynamic content) {
    if (content is List) {
      return JsonArrayViewer(content, notRoot: true);
    } else {
      return JsonObjectViewer(content, notRoot: true);
    }
  }

  static isInkWell(dynamic content) {
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

  getValueWidget(MapEntry<String, dynamic> entry) {
    if (entry.value == null) {
      return const Expanded(
        child: SelectableText(
          'undefined',
          style: TextStyle(color: Colors.grey),
        ),
      );
    } else if (entry.value is int) {
      return Expanded(
        child: SelectableText(
          entry.value.toString(),
          style: const TextStyle(color: Color(0xff6491b3)),
        ),
      );
    } else if (entry.value is String) {
      return Expanded(
        child: SelectableText(
          "\"${entry.value}\"",
          style: const TextStyle(color: Color(0xff6a8759)),
        ),
      );
    } else if (entry.value is bool) {
      return Expanded(
        child: SelectableText(
          entry.value.toString(),
          style: const TextStyle(color: Color(0xffca7832)),
        ),
      );
    } else if (entry.value is double) {
      return Expanded(
        child: SelectableText(
          entry.value.toString(),
          style: const TextStyle(color: Color(0xff6491b3)),
        ),
      );
    } else if (entry.value is List) {
      if (entry.value.isEmpty) {
        return InkWell(
          onTap: () {
            setState(() {
              openFlag[entry.key] = !(openFlag[entry.key] ?? false);
            });
          },
          onDoubleTap: () {
            Clipboard.setData(ClipboardData(
              text: jsonEncode(entry.value),
            )).then((_) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const CustomSnackBar());
            });
          },
          child: const Text(
            'Array[0]',
            style: TextStyle(color: Colors.grey),
          ),
        );
      } else {
        return InkWell(
          onTap: () {
            setState(() {
              openFlag[entry.key] = !(openFlag[entry.key] ?? false);
            });
          },
          onDoubleTap: () {
            Clipboard.setData(ClipboardData(text: jsonEncode(entry.value)))
                .then((_) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const CustomSnackBar());
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
        Clipboard.setData(ClipboardData(text: jsonEncode(entry.value)))
            .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(const CustomSnackBar());
        });
      },
      child: const Text(
        'Object',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  static isExtensible(dynamic content) {
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

  static getTypeName(dynamic content) {
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
  final List<dynamic> jsonArray;

  final bool notRoot;

  const JsonArrayViewer(this.jsonArray, {super.key, this.notRoot = false});

  @override
  _JsonArrayViewerState createState() => _JsonArrayViewerState();
}

class _JsonArrayViewerState extends State<JsonArrayViewer> {
  late List<bool> openFlag;

  @override
  Widget build(BuildContext context) {
    if (widget.notRoot) {
      return Container(
        padding: const EdgeInsets.only(left: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _getList(),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _getList(),
    );
  }

  @override
  void initState() {
    super.initState();
    openFlag = List.filled(widget.jsonArray.length, false);
  }

  _getList() {
    List<Widget> list = [];
    for (int i = 0; i < widget.jsonArray.length; i++) {
      final content = widget.jsonArray[i];
      bool ex = JsonObjectViewerState.isExtensible(content);
      bool ink = JsonObjectViewerState.isInkWell(content);
      list.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ex
                ? (openFlag[i])
                    ? InkWell(
                        onTap: () {
                          setState(() {
                            openFlag[i] = !(openFlag[i]);
                          });
                        },
                        child: Icon(
                          Icons.arrow_drop_down,
                          size: 14,
                          color: Colors.grey[700],
                        ),
                      )
                    : InkWell(
                        onTap: () {
                          setState(() {
                            openFlag[i] = !(openFlag[i]);
                          });
                        },
                        child: Icon(
                          Icons.arrow_right,
                          size: 14,
                          color: Colors.grey[700],
                        ),
                      )
                : InkWell(
                    onTap: () {
                      setState(() {
                        openFlag[i] = !(openFlag[i]);
                      });
                    },
                    child: const Icon(
                      Icons.arrow_right,
                      color: Color.fromARGB(0, 0, 0, 0),
                      size: 14,
                    ),
                  ),
            (ex && ink)
                ? getInkWell(i)
                : Text(
                    '[$i]',
                    style: TextStyle(
                      color: content == null ? Colors.grey : Colors.black,
                    ),
                  ),
            const Text(
              ':',
              style: TextStyle(color: Colors.grey),
            ),
            Padding(padding: EdgeInsets.only(left: 3)),
            getValueWidget(content, i)
          ],
        ),
      );
      list.add(Padding(padding: EdgeInsets.only(top: 4)));
      if (openFlag[i]) {
        list.add(JsonObjectViewerState.getContentWidget(content));
      }
    }
    return list;
  }

  getInkWell(int index) {
    return Text('[$index]', style: TextStyle(color: Colors.black));
  }

  getValueWidget(dynamic content, int index) {
    if (content == null) {
      return const Expanded(
        child: SelectableText(
          'undefined',
          style: TextStyle(color: Colors.grey),
        ),
      );
    } else if (content is int) {
      return Expanded(
        child: SelectableText(
          content.toString(),
          style: const TextStyle(color: Color(0xff6491b3)),
        ),
      );
    } else if (content is String) {
      return Expanded(
        child: SelectableText(
          "\"$content\"",
          style: const TextStyle(color: Color(0xff6a8759)),
        ),
      );
    } else if (content is bool) {
      return Expanded(
        child: SelectableText(
          content.toString(),
          style: const TextStyle(color: Color(0xffca7832)),
        ),
      );
    } else if (content is double) {
      return Expanded(
        child: SelectableText(
          content.toString(),
          style: const TextStyle(color: Color(0xff6491b3)),
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
            Clipboard.setData(ClipboardData(text: jsonEncode(content)))
                .then((_) {
              ScaffoldMessenger.of(context).showSnackBar(const CustomSnackBar());
            });
          },
          child: const Text(
            'Array[0]',
            style: TextStyle(color: Colors.grey),
          ),
        );
      } else {
        return InkWell(
          onTap: () {
            setState(() {
              openFlag[index] = !openFlag[index];
            });
          },
          onDoubleTap: () {
            Clipboard.setData(ClipboardData(text: jsonEncode(content)))
                .then((_) {
              ScaffoldMessenger.of(context).showSnackBar(const CustomSnackBar());
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
          ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar());
        });
      },
      child: const Text(
        'Object',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}

class CustomSnackBar extends SnackBar {
  const CustomSnackBar({
    super.key,
    super.backgroundColor = Colors.yellow,
    super.content = const Text(
      'Copied to your clipboard !',
      style: TextStyle(
        color: Colors.black,
      ),
    ),
  });

  Widget build(BuildContext context) {
    return SnackBar(
      backgroundColor: backgroundColor,
      content: content,
    );
  }
}
