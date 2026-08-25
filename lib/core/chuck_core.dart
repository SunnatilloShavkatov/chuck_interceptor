import 'dart:async';
import 'dart:convert';

import 'package:chuck_interceptor/core/chuck_cache_decoder.dart';
import 'package:chuck_interceptor/core/chuck_utils.dart';
import 'package:chuck_interceptor/helper/chuck_save_helper.dart';
import 'package:chuck_interceptor/model/chuck_http_error.dart';
import 'package:chuck_interceptor/model/chuck_http_call.dart';
import 'package:chuck_interceptor/model/chuck_http_response.dart';
import 'package:chuck_interceptor/ui/page/chuck_calls_list_screen.dart';
import 'package:chuck_interceptor/utils/shake_detector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:rxdart/rxdart.dart';

/// Width of the cache box keys, enough to hold any microsecond timestamp that
/// fits in an int without ever changing the number of digits.
const int _cacheKeyWidth = 19;

/// Box key under which the user selected cache size is persisted.
///
/// It is deliberately not a padded number, so it never collides with a call
/// key, and every read path skips it: [ChuckCacheDecoder] ignores it because
/// its value is an int rather than an encoded call, and the trim and clear
/// paths filter it out explicitly so the preference outlives the calls it
/// controls.
const String _cacheCountKey = '__chuck_max_cache_count__';

class ChuckCore {
  /// Should user be notified with notification if there's new request catch
  /// by Chuck
  final bool showNotification;

  /// Should inspector be opened on device shake (works only with physical
  /// with sensors)
  final bool showInspectorOnShake;

  /// Should inspector use dark theme
  final bool darkTheme;

  /// Rx subject which contains all intercepted http calls
  final BehaviorSubject<List<ChuckHttpCall>> callsSubject =
      BehaviorSubject.seeded([]);

  /// Icon url for notification
  final String notificationIcon;

  ///Max number of calls that are stored in memory. When count is reached, FIFO
  ///method queue will be used to remove elements.
  final int maxCallsCount;

  ///Cache sizes the user can pick from in the inspector. Zero disables the
  ///cache entirely.
  static const List<int> cacheCountOptions = <int>[0, 100, 200, 300, 1000];

  ///Max number of calls persisted in [cacheBox]. When the count is reached,
  ///oldest entries are deleted so that only the newest calls remain. Zero
  ///means nothing is persisted at all.
  ///
  ///Changes through [setMaxCacheCount] notify listeners, so the inspector
  ///reflects a new size right away.
  late final ValueNotifier<int> maxCacheCountNotifier;

  ///Currently applied cache size. See [maxCacheCountNotifier].
  int get maxCacheCount => maxCacheCountNotifier.value;

  ///Directionality of app. If null then directionality of context will be used.
  final TextDirection? directionality;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  GlobalKey<NavigatorState>? navigatorKey;
  Brightness _brightness = Brightness.light;
  bool _isInspectorOpened = false;
  ShakeDetector? _shakeDetector;
  StreamSubscription<dynamic>? _callsSubscription;
  String? _notificationMessage;
  String? _notificationMessageShown;
  bool _notificationProcessing = false;
  Box<dynamic>? cacheBox;

  /// Memoizes the decoded contents of [cacheBox] so that a box write does not
  /// force a full re-decode in every listening screen.
  final ChuckCacheDecoder cacheDecoder = ChuckCacheDecoder();

  /// Creates Chuck core instance
  ChuckCore(
    this.navigatorKey, {
    required this.showNotification,
    required this.showInspectorOnShake,
    required this.darkTheme,
    required this.notificationIcon,
    required this.maxCallsCount,
    int maxCacheCount = 0,
    this.directionality,
    this.cacheBox,
  }) {
    if (showNotification) {
      _initializeNotificationsPlugin();
      _callsSubscription = callsSubject.listen((_) => _onCallsChanged());
    }
    if (showInspectorOnShake) {
      _shakeDetector = ShakeDetector.autoStart(
        onPhoneShake: () {
          navigateToCallListScreen();
        },
        shakeThresholdGravity: 5,
      );
    }
    _brightness = darkTheme ? Brightness.dark : Brightness.light;
    maxCacheCountNotifier = ValueNotifier<int>(
      _persistedMaxCacheCount() ?? maxCacheCount,
    );
    // Applies the stored size to a box written before it was set, and empties
    // the box outright while the cache is disabled.
    _trimCache();
  }

  /// Dispose subjects and subscriptions
  void dispose() {
    callsSubject.close();
    _shakeDetector?.stopListening();
    _callsSubscription?.cancel();
    maxCacheCountNotifier.dispose();
  }

  /// Get currently used brightness
  Brightness get brightness => _brightness;

  void _initializeNotificationsPlugin() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final initializationSettingsAndroid = AndroidInitializationSettings(
      notificationIcon,
    );
    const initializationSettingsIOS = DarwinInitializationSettings();
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      linux: LinuxInitializationSettings(defaultActionName: 'default'),
      macOS: initializationSettingsIOS,
    );
    _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onSelectedNotification,
    );
  }

  void _onCallsChanged() async {
    if (callsSubject.value.isNotEmpty) {
      _notificationMessage = _getNotificationMessage();
      if (_notificationMessage != _notificationMessageShown &&
          !_notificationProcessing) {
        await _showLocalNotification();
        _onCallsChanged();
      }
    }
  }

  Future<void> _onSelectedNotification(NotificationResponse payload) async {
    navigateToCallListScreen();
    return;
  }

  /// Opens Http calls inspector. This will navigate user to the new fullscreen
  /// page where all listened http calls can be viewed.
  void navigateToCallListScreen() {
    final context = getContext();
    if (context == null) {
      ChuckUtils.log(
        "Cant start Chuck HTTP Inspector. Please add NavigatorKey to your application",
      );
      return;
    }
    if (!_isInspectorOpened) {
      _isInspectorOpened = true;
      Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (context) => ChuckCallsListScreen(this)),
      ).then((onValue) => _isInspectorOpened = false);
    }
  }

  /// Get context from navigator key. Used to open inspector route.
  BuildContext? getContext() => navigatorKey?.currentState?.overlay?.context;

  String _getNotificationMessage() {
    final List<ChuckHttpCall> calls = callsSubject.value;
    final int successCalls = calls
        .where(
          (call) =>
              call.response != null &&
              (call.response!.status ?? 0) >= 200 &&
              (call.response!.status ?? 0) < 300,
        )
        .toList()
        .length;

    final int redirectCalls = calls
        .where(
          (call) =>
              call.response != null &&
              (call.response!.status ?? 0) >= 300 &&
              (call.response!.status ?? 0) < 400,
        )
        .toList()
        .length;

    final int errorCalls = calls
        .where(
          (call) =>
              call.response != null &&
              (call.response!.status ?? 0) >= 400 &&
              (call.response!.status ?? 0) < 600,
        )
        .toList()
        .length;

    final int loadingCalls = calls
        .where((call) => call.loading)
        .toList()
        .length;

    final StringBuffer notificationsMessage = StringBuffer();
    if (loadingCalls > 0) {
      notificationsMessage.write("Loading: $loadingCalls");
      notificationsMessage.write(" | ");
    }
    if (successCalls > 0) {
      notificationsMessage.write("Success: $successCalls");
      notificationsMessage.write(" | ");
    }
    if (redirectCalls > 0) {
      notificationsMessage.write("Redirect: $redirectCalls");
      notificationsMessage.write(" | ");
    }
    if (errorCalls > 0) {
      notificationsMessage.write("Error: $errorCalls");
    }
    String notificationMessageString = notificationsMessage.toString();
    if (notificationMessageString.endsWith(" | ")) {
      notificationMessageString = notificationMessageString.substring(
        0,
        notificationMessageString.length - 3,
      );
    }

    return notificationMessageString;
  }

  Future<void> _showLocalNotification() async {
    _notificationProcessing = true;
    const channelId = "Chuck";
    const channelName = "Chuck";
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId,
      channelName,
      enableVibration: false,
      playSound: false,
      largeIcon: DrawableResourceAndroidBitmap(notificationIcon),
    );
    const iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentSound: false,
    );
    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    final String? message = _notificationMessage;
    await _flutterLocalNotificationsPlugin.show(
      id: 0,
      body: message,
      payload: "chuck_interceptor",
      title: "Chuck (total: ${callsSubject.value.length} requests)",
      notificationDetails: platformChannelSpecifics,
    );
    _notificationMessageShown = message;
    _notificationProcessing = false;
    return;
  }

  /// Add Chuck http call to calls subject
  void addCall(ChuckHttpCall call) {
    final callsCount = callsSubject.value.length;
    if (callsCount >= maxCallsCount) {
      final originalCalls = callsSubject.value;
      final calls = List<ChuckHttpCall>.from(originalCalls);
      calls.sort(
        (call1, call2) => call1.createdTime.compareTo(call2.createdTime),
      );
      final indexToReplace = originalCalls.indexOf(calls.first);
      originalCalls[indexToReplace] = call;

      callsSubject.add(originalCalls);
    } else {
      callsSubject.add([...callsSubject.value, call]);
    }
  }

  /// Add error to existing Chuck http call
  void addError(ChuckHttpError error, int requestId) {
    final ChuckHttpCall? selectedCall = _selectCall(requestId);

    if (selectedCall == null) {
      ChuckUtils.log("Selected call is null");
      return;
    }

    selectedCall.error = error;
    _cacheCall(selectedCall);
    callsSubject.add([...callsSubject.value]);
  }

  /// Add response to existing Chuck http call
  void addResponse(ChuckHttpResponse response, int requestId) {
    final ChuckHttpCall? selectedCall = _selectCall(requestId);

    if (selectedCall == null) {
      ChuckUtils.log("Selected call is null");
      return;
    }
    selectedCall.loading = false;
    selectedCall.response = response;
    selectedCall.duration =
        response.time.millisecondsSinceEpoch -
        selectedCall.request!.time.millisecondsSinceEpoch;
    _cacheCall(selectedCall);
    callsSubject.add([...callsSubject.value]);
  }

  /// Add Chuck http call to calls subject
  void addHttpCall(ChuckHttpCall ChuckHttpCall) {
    assert(ChuckHttpCall.request != null, "Http call request can't be null");
    assert(ChuckHttpCall.response != null, "Http call response can't be null");
    callsSubject.add([...callsSubject.value, ChuckHttpCall]);
  }

  /// Remove all calls from calls subject
  void removeCalls() {
    callsSubject.add([]);
  }

  /// Persist call in [cacheBox] and keep only newest [maxCacheCount] entries.
  ///
  /// Key is the call creation timestamp, so it is monotonic: Hive keeps its
  /// keystore sorted by key, which makes the leading keys the oldest entries
  /// and eviction a plain FIFO. The key is also stable for a given call, so
  /// writing the response and then the error of the same call overwrites one
  /// entry instead of appending duplicates.
  ///
  /// Hive only accepts integer keys up to 0xFFFFFFFF, which a microsecond
  /// timestamp overflows, so the key is a zero padded string of fixed width
  /// and its lexicographic order matches its numeric order. Keys written by
  /// older versions are plain ints, and Hive sorts every int key before every
  /// string key, so those legacy entries are evicted first.
  void _cacheCall(ChuckHttpCall call) {
    final Box<dynamic>? box = cacheBox;
    if (box == null) {
      return;
    }

    if (maxCacheCount <= 0) {
      return;
    }

    final String key = call.createdTime.microsecondsSinceEpoch
        .toString()
        .padLeft(_cacheKeyWidth, '0');
    _guardCacheWrite(box.put(key, jsonEncode(call.toJson())));
    // Hive applies the write to its keystore synchronously, so the length below
    // already accounts for the entry just written.
    _trimCache();
  }

  /// Drop the oldest entries until [cacheBox] holds at most [maxCacheCount].
  ///
  /// Runs on every write and once when Chuck starts. The startup pass matters
  /// for a box written by a version that never trimmed: without it the box
  /// keeps its whole backlog until the first call of the session, so opening
  /// the inspector before that decodes every stale entry.
  void _trimCache() {
    final Box<dynamic>? box = cacheBox;
    if (box == null) {
      return;
    }

    final List<dynamic> keys = _callKeys(box);
    final int overflow = keys.length - maxCacheCount;
    if (overflow > 0) {
      _guardCacheWrite(box.deleteAll(keys.take(overflow).toList()));
    }
  }

  /// Keys of [box] that hold calls, oldest first, excluding the stored
  /// preference.
  List<dynamic> _callKeys(Box<dynamic> box) =>
      box.keys.where((dynamic key) => key != _cacheCountKey).toList();

  /// Cache size stored by a previous session, or null when unset or no longer
  /// offered in [cacheCountOptions].
  int? _persistedMaxCacheCount() {
    final dynamic stored = cacheBox?.get(_cacheCountKey);
    return stored is int && cacheCountOptions.contains(stored) ? stored : null;
  }

  /// Apply and persist a new cache size picked by the user.
  ///
  /// Shrinking drops the oldest calls immediately, and zero empties the cache
  /// while keeping the choice itself, so the next launch stays disabled.
  void setMaxCacheCount(int value) {
    if (!cacheCountOptions.contains(value)) {
      return;
    }

    maxCacheCountNotifier.value = value;
    final Box<dynamic>? box = cacheBox;
    // Persisted whenever it differs on disk, even when it matches the value
    // already in memory: that value may only be the default supplied by the
    // host app, and an explicit pick has to outlive a change of that default.
    if (box != null && _persistedMaxCacheCount() != value) {
      _guardCacheWrite(box.put(_cacheCountKey, value));
    }
    _trimCache();
  }

  /// Delete every cached call, keeping the stored cache size.
  void clearCache() {
    final Box<dynamic>? box = cacheBox;
    if (box == null) {
      return;
    }

    _guardCacheWrite(box.deleteAll(_callKeys(box)));
  }

  /// Swallow failures of a fire and forget cache write.
  ///
  /// The box belongs to the host app and can be closed while a write is still
  /// in flight, which would otherwise surface as an unhandled error in the app
  /// Chuck is only supposed to be inspecting.
  void _guardCacheWrite(Future<void> write) {
    unawaited(
      write.catchError((Object error) {
        ChuckUtils.log("Chuck failed to write to the cache box: $error");
      }),
    );
  }

  ChuckHttpCall? _selectCall(int requestId) =>
      callsSubject.value.firstWhere((call) => call.id == requestId);

  /// Save all calls to file
  void saveHttpRequests(BuildContext context) {
    ChuckSaveHelper.saveCalls(context, callsSubject.value, _brightness);
  }
}
