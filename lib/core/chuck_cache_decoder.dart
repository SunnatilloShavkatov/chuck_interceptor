import 'dart:convert';

import 'package:chuck_interceptor/model/chuck_http_call.dart';
import 'package:hive/hive.dart';

/// Decodes the json payloads persisted in the cache box and memoizes the
/// result per box key.
///
/// The cache box notifies its listeners on every single write, so a naive
/// builder re-runs [jsonDecode] over every entry on every intercepted call.
/// This decoder keeps the previously decoded call and reuses it while the
/// underlying raw value is unchanged, so a write only costs one decode.
class ChuckCacheDecoder {
  final Map<dynamic, _DecodedEntry> _entries = <dynamic, _DecodedEntry>{};

  /// Decoded calls of [box], in box key order (oldest first).
  ///
  /// Entries that are still backed by the same raw value are returned from the
  /// memo, entries that were written or replaced since the last call are
  /// decoded again, and entries evicted from the box are dropped.
  List<ChuckHttpCall> decodeCalls(Box<dynamic> box) {
    final List<ChuckHttpCall> calls = <ChuckHttpCall>[];
    final Set<dynamic> seenKeys = <dynamic>{};

    for (final dynamic key in box.keys) {
      final dynamic raw = box.get(key);
      if (raw is! String) {
        continue;
      }

      seenKeys.add(key);
      _DecodedEntry? entry = _entries[key];
      // Hive hands back the very same String instance until the value is
      // overwritten, so identity is enough to detect a stale memo. A false
      // miss only costs one extra decode.
      if (entry == null || !identical(entry.raw, raw)) {
        entry = _DecodedEntry(raw, ChuckHttpCall.fromJson(jsonDecode(raw)));
        _entries[key] = entry;
      }
      calls.add(entry.call);
    }

    if (seenKeys.length != _entries.length) {
      _entries.removeWhere((dynamic key, _) => !seenKeys.contains(key));
    }

    return calls;
  }

  /// Drop every memoized call.
  void clear() {
    _entries.clear();
  }
}

class _DecodedEntry {
  _DecodedEntry(this.raw, this.call);

  final String raw;
  final ChuckHttpCall call;
}
