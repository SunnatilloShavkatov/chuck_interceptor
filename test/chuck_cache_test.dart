import 'dart:convert';
import 'dart:io';
import 'package:chuck_interceptor/core/chuck_cache_decoder.dart';
import 'package:chuck_interceptor/core/chuck_core.dart';
import 'package:chuck_interceptor/model/chuck_http_call.dart';
import 'package:chuck_interceptor/model/chuck_http_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

String enc(int id, DateTime t) {
  final c = ChuckHttpCall(id, t)
    ..endpoint = "/e$id"
    ..request = ChuckHttpRequest(time: t, headers: {}, body: "", size: 0, contentType: "application/json");
  return jsonEncode(c.toJson());
}

ChuckCore core(Box<dynamic> box, {int maxCacheCount = 0}) => ChuckCore(
      null,
      showNotification: false,
      showInspectorOnShake: false,
      darkTheme: false,
      notificationIcon: "@mipmap/ic_launcher",
      maxCallsCount: 1000,
      maxCacheCount: maxCacheCount,
      cacheBox: box,
    );

void main() {
  late Box<dynamic> box;

  setUp(() async {
    Hive.init('${Directory.systemTemp.path}/chuck_test_${DateTime.now().microsecondsSinceEpoch}');
    box = await Hive.openBox<dynamic>('b');
  });
  tearDown(() async => Hive.deleteFromDisk());

  test('FIFO keeps newest N', () async {
    final base = DateTime(2026, 1, 1);
    for (var i = 0; i < 250; i++) {
      final t = base.add(Duration(seconds: i));
      await box.put(t.microsecondsSinceEpoch.toString().padLeft(19, '0'), enc(i, t));
      final overflow = box.length - 100;
      if (overflow > 0) await box.deleteAll(box.keys.take(overflow).toList());
    }
    expect(box.length, 100);
    final calls = ChuckCacheDecoder().decodeCalls(box);
    expect(calls.first.id, 150);
    expect(calls.last.id, 249);
  });

  test('legacy oversized box is trimmed on startup, legacy keys go first',
      () async {
    final base = DateTime(2026, 1, 1);
    // Entries written by an older version: plain auto increment int keys.
    for (var i = 0; i < 5000; i++) {
      await box.add(enc(i, base.add(Duration(seconds: i))));
    }
    // Entries written by the current version: padded string keys.
    for (var i = 5000; i < 5050; i++) {
      final t = base.add(Duration(seconds: i));
      await box.put(t.microsecondsSinceEpoch.toString().padLeft(19, '0'), enc(i, t));
    }
    expect(box.length, 5050);

    core(box, maxCacheCount: 100);

    expect(box.length, 100);
    final calls = ChuckCacheDecoder().decodeCalls(box);
    // 50 newest legacy int keyed entries, then the 50 string keyed ones.
    expect(calls.first.id, 4950);
    expect(calls.last.id, 5049);

    // Let the fire and forget delete finish before tearDown closes the box.
    await box.flush();
  });

  test('same call overwrites, no duplicate', () async {
    final t = DateTime(2026, 1, 1);
    await box.put(t.microsecondsSinceEpoch.toString().padLeft(19, '0'), enc(7, t));
    await box.put(t.microsecondsSinceEpoch.toString().padLeft(19, '0'), enc(7, t));
    expect(box.length, 1);
  });

  test('decoder memoizes unchanged entries', () async {
    final base = DateTime(2026, 1, 1);
    for (var i = 0; i < 10; i++) {
      final t = base.add(Duration(seconds: i));
      await box.put(t.microsecondsSinceEpoch.toString().padLeft(19, '0'), enc(i, t));
    }
    final d = ChuckCacheDecoder();
    final first = d.decodeCalls(box);
    final second = d.decodeCalls(box);
    for (var i = 0; i < first.length; i++) {
      expect(identical(first[i], second[i]), isTrue, reason: 'entry $i re-decoded');
    }

    final newT = base.add(const Duration(seconds: 99));
    await box.put(newT.microsecondsSinceEpoch.toString().padLeft(19, '0'), enc(99, newT));
    final third = d.decodeCalls(box);
    expect(third.length, 11);
    for (var i = 0; i < 10; i++) {
      expect(identical(second[i], third[i]), isTrue, reason: 'entry $i re-decoded after unrelated write');
    }
  });

  test('evicted keys drop out of memo', () async {
    final base = DateTime(2026, 1, 1);
    for (var i = 0; i < 5; i++) {
      final t = base.add(Duration(seconds: i));
      await box.put(t.microsecondsSinceEpoch.toString().padLeft(19, '0'), enc(i, t));
    }
    final d = ChuckCacheDecoder();
    expect(d.decodeCalls(box).length, 5);
    await box.deleteAll(box.keys.take(3).toList());
    final after = d.decodeCalls(box);
    expect(after.length, 2);
    expect(after.first.id, 3);
  });

  group('cache size preference', () {
    Future<void> seed(int count) async {
      final base = DateTime(2026, 1, 1);
      for (var i = 0; i < count; i++) {
        final t = base.add(Duration(seconds: i));
        await box.put(
          t.microsecondsSinceEpoch.toString().padLeft(19, '0'),
          enc(i, t),
        );
      }
    }

    test('defaults to off and empties an existing cache', () async {
      await seed(40);
      core(box);
      await box.flush();
      expect(box.isEmpty, isTrue);
    });

    test('a fresh box is left completely untouched', () async {
      core(box);
      await box.flush();
      // Not even the preference is written until the user picks a size.
      expect(box.keys, isEmpty);
    });

    test('a stored size is honoured instead of the default, cache survives',
        () async {
      core(box).setMaxCacheCount(100);
      await seed(40);
      await box.flush();

      // Next launch passes the default of 0, but the stored 100 must win and
      // the cached calls must stay.
      final relaunched = core(box);
      await box.flush();
      expect(relaunched.maxCacheCount, 100);
      expect(ChuckCacheDecoder().decodeCalls(box).length, 40);
    });

    test('disabled core writes nothing', () async {
      final c = core(box);
      final t = DateTime(2026, 1, 2);
      await box.put(
        t.microsecondsSinceEpoch.toString().padLeft(19, '0'),
        enc(1, t),
      );
      // Anything written while disabled is dropped on the next trim.
      c.setMaxCacheCount(100);
      c.setMaxCacheCount(0);
      await box.flush();
      expect(ChuckCacheDecoder().decodeCalls(box), isEmpty);
    });

    test('choice survives a restart and is not evicted as a call', () async {
      core(box).setMaxCacheCount(100);
      await box.flush();

      // New session: no explicit size passed, the stored one must win.
      final restarted = core(box);
      expect(restarted.maxCacheCount, 100);

      // A box that grew past the stored size is trimmed by the next startup.
      await seed(250);
      final afterGrowth = core(box);
      await box.flush();
      expect(afterGrowth.maxCacheCount, 100);
      expect(ChuckCacheDecoder().decodeCalls(box).length, 100);
    });

    test('shrinking keeps the newest calls', () async {
      final c = core(box, maxCacheCount: 300);
      await seed(300);
      c.setMaxCacheCount(100);
      await box.flush();
      final calls = ChuckCacheDecoder().decodeCalls(box);
      expect(calls.length, 100);
      expect(calls.first.id, 200);
      expect(calls.last.id, 299);
    });

    test('clearCache drops calls but keeps the choice', () async {
      final c = core(box, maxCacheCount: 300);
      c.setMaxCacheCount(300);
      await seed(20);
      c.clearCache();
      await box.flush();
      expect(ChuckCacheDecoder().decodeCalls(box), isEmpty);
      expect(core(box).maxCacheCount, 300);
    });

    test('only offered sizes are accepted', () async {
      final c = core(box);
      c.setMaxCacheCount(7);
      expect(c.maxCacheCount, 0);
      c.setMaxCacheCount(1000);
      expect(c.maxCacheCount, 1000);
    });
  });
}
