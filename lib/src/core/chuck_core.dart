import 'dart:async';

import 'package:chuck_interceptor/src/core/chuck_utils.dart';
import 'package:chuck_interceptor/src/helper/chuck_save_helper.dart';
import 'package:chuck_interceptor/src/model/chuck_http_error.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/model/chuck_http_response.dart';
import 'package:chuck_interceptor/src/ui/page/chuck_calls_list_screen.dart';
import 'package:chuck_interceptor/src/utils/shake_detector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';

/// Core class that manages HTTP call interception, storage, and UI navigation.
///
/// This class provides the main functionality for:
/// - Intercepting and storing HTTP requests/responses
/// - Managing notifications for new HTTP calls
/// - Handling shake-to-open functionality
/// - Memory management with configurable call limits
/// - Navigation to the inspector UI
///
/// The class uses RxDart's BehaviorSubject for reactive state management,
/// ensuring that UI components automatically update when new HTTP calls are added.
class ChuckCore {
  /// Whether to show notifications when new HTTP requests are intercepted
  final bool showNotification;

  /// Whether to open the inspector when the device is shaken (physical devices only)
  final bool showInspectorOnShake;

  /// Reactive stream containing all intercepted HTTP calls
  /// Uses BehaviorSubject to maintain the latest state and allow new subscribers
  /// to receive the current value immediately
  final BehaviorSubject<List<ChuckHttpCall>> callsSubject = BehaviorSubject.seeded([]);

  /// Resource name for the notification icon (Android only)
  final String notificationIcon;

  /// Maximum number of HTTP calls to store in memory
  /// When this limit is reached, the oldest calls are removed using FIFO policy
  final int maxCallsCount;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  GlobalKey<NavigatorState>? navigatorKey;
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
    required this.notificationIcon,
    required this.maxCallsCount,
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
  }

  /// Dispose subjects and subscriptions
  void dispose() {
    callsSubject.close();
    _shakeDetector?.stopListening();
    _callsSubscription?.cancel();
  }

  void _initializeNotificationsPlugin() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final initializationSettingsAndroid = AndroidInitializationSettings(notificationIcon);
    const initializationSettingsIOS = DarwinInitializationSettings();
    final initializationSettings = InitializationSettings(
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsIOS,
      android: initializationSettingsAndroid,
      linux: LinuxInitializationSettings(defaultActionName: 'default'),
    );
    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onSelectedNotification,
    );
  }

  void _onCallsChanged() async {
    if (callsSubject.value.isNotEmpty && !_notificationProcessing) {
      _notificationMessage = _getNotificationMessage();
      if (_notificationMessage != _notificationMessageShown) {
        await _showLocalNotification();
        // Remove recursive call to prevent potential stack overflow
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
      ChuckUtils.log("Cant start Chuck HTTP Inspector. Please add NavigatorKey to your application");
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
        .where((call) => call.response != null && call.response!.status! >= 200 && call.response!.status! < 300)
        .toList()
        .length;

    final int redirectCalls = calls
        .where((call) => call.response != null && call.response!.status! >= 300 && call.response!.status! < 400)
        .toList()
        .length;

    final int errorCalls = calls
        .where((call) => call.response != null && call.response!.status! >= 400 && call.response!.status! < 600)
        .toList()
        .length;

    final int loadingCalls = calls.where((call) => call.loading).toList().length;

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
      notificationMessageString = notificationMessageString.substring(0, notificationMessageString.length - 3);
    }

    return notificationMessageString;
  }

  /// Show local notification with improved error handling
  Future<void> _showLocalNotification() async {
    try {
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
      const iOSPlatformChannelSpecifics = DarwinNotificationDetails(presentSound: false);
      final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
      final String? message = _notificationMessage;
      await _flutterLocalNotificationsPlugin.show(
        0,
        "Chuck (total: ${callsSubject.value.length} requests)",
        message,
        platformChannelSpecifics,
        payload: "",
      );
      _notificationMessageShown = message;
    } catch (e) {
      ChuckUtils.log("Error showing notification: $e");
    } finally {
      _notificationProcessing = false;
    }
  }

  /// Add Chuck http call to calls subject with optimized memory management
  void addCall(ChuckHttpCall call) {
    final List<ChuckHttpCall> currentCalls = callsSubject.value;

    if (currentCalls.length >= maxCallsCount) {
      // Find and remove the oldest call more efficiently
      ChuckHttpCall? oldestCall;
      int oldestIndex = -1;

      for (int i = 0; i < currentCalls.length; i++) {
        if (oldestCall == null || currentCalls[i].createdTime.isBefore(oldestCall.createdTime)) {
          oldestCall = currentCalls[i];
          oldestIndex = i;
        }
      }

      if (oldestIndex >= 0) {
        // Create new list with the oldest call replaced
        final List<ChuckHttpCall> updatedCalls = [...currentCalls];
        updatedCalls[oldestIndex] = call;
        callsSubject.add(updatedCalls);
      } else {
        // Fallback: add to existing list
        callsSubject.add([...currentCalls, call]);
      }
    } else {
      // Efficiently add new call to existing list
      callsSubject.add([...currentCalls, call]);
    }
  }

  /// Add error to existing Chuck http call with improved error handling
  void addError(ChuckHttpError<dynamic> error, int requestId) {
    try {
      final ChuckHttpCall? selectedCall = _selectCall(requestId);

      if (selectedCall == null) {
        ChuckUtils.log("Warning: Call with ID $requestId not found when adding error");
        return;
      }

      selectedCall.error = error;
      // Trigger update with the modified call
      final List<ChuckHttpCall> currentCalls = callsSubject.value;
      callsSubject.add([...currentCalls]);
    } catch (e) {
      ChuckUtils.log("Error adding error to call $requestId: $e");
    }
  }

  /// Add response to existing Chuck http call with improved error handling
  void addResponse(ChuckHttpResponse response, int requestId) {
    try {
      final ChuckHttpCall? selectedCall = _selectCall(requestId);

      if (selectedCall == null) {
        ChuckUtils.log("Warning: Call with ID $requestId not found when adding response");
        return;
      }

      if (selectedCall.request == null) {
        ChuckUtils.log("Warning: Request is null for call $requestId");
        return;
      }

      selectedCall.loading = false;
      selectedCall.response = response;
      selectedCall.duration = response.time.millisecondsSinceEpoch - selectedCall.request!.time.millisecondsSinceEpoch;

      // Trigger update with the modified call
      final List<ChuckHttpCall> currentCalls = callsSubject.value;
      callsSubject.add([...currentCalls]);
    } catch (e) {
      ChuckUtils.log("Error adding response to call $requestId: $e");
    }
  }

  /// Add Chuck http call to calls subject
  void addHttpCall(ChuckHttpCall chuckHttpCall) {
    assert(chuckHttpCall.request != null, "Http call request can't be null");
    assert(chuckHttpCall.response != null, "Http call response can't be null");
    callsSubject.add([...callsSubject.value, chuckHttpCall]);
  }

  /// Remove all calls from calls subject
  void removeCalls() {
    callsSubject.add([]);
  }

  /// Find a specific call by ID with improved error handling
  ChuckHttpCall? _selectCall(int requestId) {
    try {
      final calls = callsSubject.value;
      for (final call in calls) {
        if (call.id == requestId) {
          return call;
        }
      }
      return null;
    } catch (e) {
      ChuckUtils.log("Error finding call with ID $requestId: $e");
      return null;
    }
  }

  /// Save all calls to file
  void saveHttpRequests(BuildContext context) {
    ChuckSaveHelper.saveCalls(context, callsSubject.value, Theme.of(context).brightness);
  }
}
