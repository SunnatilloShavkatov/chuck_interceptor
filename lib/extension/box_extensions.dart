import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Flutter extensions for boxes.
extension BoxX<T> on Box<T> {
  /// Returns a [ValueListenable] which notifies its listeners when an entry
  /// in the box changes.
  ///
  /// If [keys] filter is provided, only changes to entries with the
  /// specified keys notify the listeners.
  ValueListenable<Box<T>> listenable({List<dynamic>? keys}) => _BoxListenable(this, keys?.toSet());
}

/// Flutter extensions for lazy boxes.
extension LazyBoxX<T> on LazyBox<T> {
  /// Returns a [ValueListenable] which notifies its listeners when an entry
  /// in the box changes.
  ///
  /// If [keys] filter is provided, only changes to entries with the
  /// specified keys notify the listeners.
  ValueListenable<LazyBox<T>> listenable({List<dynamic>? keys}) => _BoxListenable(this, keys?.toSet());
}

class _BoxListenable<B extends BoxBase> extends ValueListenable<B> {
  _BoxListenable(this.box, this.keys);

  final B box;

  final Set<dynamic>? keys;

  final List<VoidCallback> _listeners = <VoidCallback>[];

  StreamSubscription? _subscription;

  @override
  void addListener(VoidCallback listener) {
    if (_listeners.isEmpty) {
      if (keys != null) {
        _subscription = box.watch().listen((BoxEvent event) {
          if (keys!.contains(event.key)) {
            for (final VoidCallback listener in _listeners) {
              listener();
            }
          }
        });
      } else {
        _subscription = box.watch().listen((_) {
          for (final VoidCallback listener in _listeners) {
            listener();
          }
        });
      }
    }

    _listeners.add(listener);
  }

  @override
  Future<void> removeListener(VoidCallback listener) async {
    _listeners.remove(listener);

    if (_listeners.isEmpty) {
      await _subscription?.cancel();
      _subscription = null;
    }
  }

  @override
  B get value => box;
}
