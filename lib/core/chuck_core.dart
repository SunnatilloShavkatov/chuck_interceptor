import 'dart:async';

import 'package:chuck_interceptor/core/chuck_utils.dart';
import 'package:chuck_interceptor/helper/chuck_save_helper.dart';
import 'package:chuck_interceptor/model/chuck_http_error.dart';
import 'package:chuck_interceptor/model/chuck_http_call.dart';
import 'package:chuck_interceptor/model/chuck_http_response.dart';
import 'package:chuck_interceptor/ui/page/chuck_calls_list_screen.dart';
import 'package:chuck_interceptor/utils/shake_detector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';

class ChuckCore {
  /// Should user be notified with notification if there's new request catched
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

  /// Creates Chuck core instance
  ChuckCore(
    this.navigatorKey, {
    required this.showNotification,
    required this.showInspectorOnShake,
    required this.darkTheme,
    required this.notificationIcon,
    required this.maxCallsCount,
    this.directionality,
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
  }

  /// Dispose subjects and subscriptions
  void dispose() {
    callsSubject.close();
    _shakeDetector?.stopListening();
    _callsSubscription?.cancel();
  }

  /// Get currently used brightness
  Brightness get brightness => _brightness;

  void _initializeNotificationsPlugin() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final initializationSettingsAndroid =
        AndroidInitializationSettings(notificationIcon);
    const initializationSettingsIOS = DarwinInitializationSettings();
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      linux: LinuxInitializationSettings(defaultActionName: 'default'),
      macOS: initializationSettingsIOS,
    );
    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onSelectedNotification,
      // onDidReceiveBackgroundNotificationResponse: _onSelectedNotification,
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
          "Cant start Chuck HTTP Inspector. Please add NavigatorKey to your application");
      return;
    }
    if (!_isInspectorOpened) {
      _isInspectorOpened = true;
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (context) => ChuckCallsListScreen(this),
        ),
      ).then((onValue) => _isInspectorOpened = false);
    }
  }

  /// Get context from navigator key. Used to open inspector route.
  BuildContext? getContext() => navigatorKey?.currentState?.overlay?.context;

  String _getNotificationMessage() {
    final List<ChuckHttpCall> calls = callsSubject.value;
    final int successCalls = calls
        .where((call) =>
            call.response != null &&
            call.response!.status! >= 200 &&
            call.response!.status! < 300)
        .toList()
        .length;

    final int redirectCalls = calls
        .where((call) =>
            call.response != null &&
            call.response!.status! >= 300 &&
            call.response!.status! < 400)
        .toList()
        .length;

    final int errorCalls = calls
        .where((call) =>
            call.response != null &&
            call.response!.status! >= 400 &&
            call.response!.status! < 600)
        .toList()
        .length;

    final int loadingCalls =
        calls.where((call) => call.loading).toList().length;

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
          0, notificationMessageString.length - 3);
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
        iOS: iOSPlatformChannelSpecifics);
    final String? message = _notificationMessage;
    await _flutterLocalNotificationsPlugin.show(
        0,
        "Chuck (total: ${callsSubject.value.length} requests)",
        message,
        platformChannelSpecifics,
        payload: "");
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
          (call1, call2) => call1.createdTime.compareTo(call2.createdTime));
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
    selectedCall.duration = response.time.millisecondsSinceEpoch -
        selectedCall.request!.time.millisecondsSinceEpoch;

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

  ChuckHttpCall? _selectCall(int requestId) =>
      callsSubject.value.firstWhere((call) => call.id == requestId);

  /// Save all calls to file
  void saveHttpRequests(BuildContext context) {
    ChuckSaveHelper.saveCalls(context, callsSubject.value, _brightness);
  }
}
