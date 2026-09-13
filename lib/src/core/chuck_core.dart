import 'dart:async';

import 'package:chuck_interceptor/src/core/chuck_utils.dart';
import 'package:chuck_interceptor/src/helper/chuck_save_helper.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/model/chuck_http_error.dart';
import 'package:chuck_interceptor/src/model/chuck_http_response.dart';
import 'package:chuck_interceptor/src/ui/page/chuck_calls_list_screen.dart';
import 'package:chuck_interceptor/src/utils/shake_detector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rxdart/rxdart.dart';

/// Core class that manages HTTP call interception, storage, and UI navigation.
///
/// This class provides the main functionality for:
/// - Intercepting and storing HTTP requests/responses
/// - Handling shake-to-open functionality
/// - Memory management with configurable call limits
/// - Navigation to the inspector UI
///
/// The class uses RxDart's BehaviorSubject for reactive state management,
/// ensuring that UI components automatically update when new HTTP calls are added.
class ChuckCore {
  /// Creates Chuck core instance
  new(
    this.navigatorKey, {
    required this.showInspectorOnShake,
    required this.maxCallsCount,
    this.enabled = true,
    this.maxBodySize = 1024 * 1024,
  }) {
    if (enabled && showInspectorOnShake) {
      _shakeDetector = ShakeDetector.autoStart(
        onPhoneShake: () {
          navigateToCallListScreen();
        },
        shakeThresholdGravity: 5,
      );
    }
  }

  /// Whether Chuck interceptor is enabled
  final bool enabled;

  /// Maximum size of request/response body in bytes to store in memory (default: 256 KB)
  final int maxBodySize;

  /// Whether to open the inspector when the device is shaken (physical devices only)
  final bool showInspectorOnShake;

  /// Reactive stream containing all intercepted HTTP calls
  /// Uses BehaviorSubject to maintain the latest state and allow new subscribers
  /// to receive the current value immediately
  final BehaviorSubject<List<ChuckHttpCall>> callsSubject = BehaviorSubject.seeded([]);

  /// Maximum number of HTTP calls to store in memory
  /// When this limit is reached, the oldest calls are removed using FIFO policy
  final int maxCallsCount;

  GlobalKey<NavigatorState>? navigatorKey;
  ShakeDetector? _shakeDetector;

  /// Whether the inspector screen is currently on top of the navigation stack.
  /// Listenable so UI (e.g. the floating Chuck button) can hide itself while it is open.
  final ValueNotifier<bool> inspectorOpened = ValueNotifier(false);

  /// Reactive stream of all intercepted HTTP calls.
  Stream<List<ChuckHttpCall>> get callsStream => callsSubject.stream;

  /// Dispose subjects and subscriptions
  void dispose() {
    unawaited(callsSubject.close());
    _shakeDetector?.stopListening();
    inspectorOpened.dispose();
  }

  /// Opens Http calls inspector. This will navigate user to the new fullscreen
  /// page where all listened http calls can be viewed.
  void navigateToCallListScreen() {
    final context = getContext();
    if (context == null) {
      ChuckUtils.log('Cant start Chuck HTTP Inspector. Please add NavigatorKey to your application');
      return;
    }
    if (!inspectorOpened.value) {
      inspectorOpened.value = true;
      Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (context) => ChuckCallsListScreen(this)),
      ).then((_) => inspectorOpened.value = false);
    }
  }

  /// Get context from navigator key. Used to open inspector route.
  BuildContext? getContext() => navigatorKey?.currentState?.overlay?.context;

  /// Add Chuck http call to calls subject with optimized memory management
  void addCall(ChuckHttpCall call) {
    if (!enabled) {
      return;
    }
    final List<ChuckHttpCall> currentCalls = List.of(callsSubject.value);

    if (currentCalls.length >= maxCallsCount) {
      currentCalls.removeAt(0);
    }
    currentCalls.add(call);
    callsSubject.add(List.unmodifiable(currentCalls));
  }

  /// Add error to existing Chuck http call with improved error handling
  void addError(ChuckHttpError<dynamic> error, int requestId) {
    if (!enabled) {
      return;
    }
    try {
      final ChuckHttpCall? selectedCall = _selectCall(requestId);

      if (selectedCall == null) {
        ChuckUtils.log('Warning: Call with ID $requestId not found when adding error');
        return;
      }

      selectedCall
        ..loading = false
        ..error = error;
      if (selectedCall.duration == 0) {
        selectedCall.duration = DateTime.now().millisecondsSinceEpoch - selectedCall.createdTime.millisecondsSinceEpoch;
      }
      // Trigger update with the modified call
      final List<ChuckHttpCall> currentCalls = List.of(callsSubject.value);
      callsSubject.add(List.unmodifiable(currentCalls));
    } catch (e) {
      ChuckUtils.log('Error adding error to call $requestId: $e');
    }
  }

  /// Add response to existing Chuck http call with improved error handling
  void addResponse(ChuckHttpResponse response, int requestId) {
    if (!enabled) {
      return;
    }
    try {
      final ChuckHttpCall? selectedCall = _selectCall(requestId);

      if (selectedCall == null) {
        ChuckUtils.log('Warning: Call with ID $requestId not found when adding response');
        return;
      }

      final requestTime = selectedCall.request?.time;
      final duration = requestTime != null
          ? response.time.millisecondsSinceEpoch - requestTime.millisecondsSinceEpoch
          : 0;

      selectedCall
        ..loading = false
        ..response = response
        ..duration = duration >= 0 ? duration : 0;

      // Trigger update with the modified call
      final List<ChuckHttpCall> currentCalls = List.of(callsSubject.value);
      callsSubject.add(List.unmodifiable(currentCalls));
    } catch (e) {
      ChuckUtils.log('Error adding response to call $requestId: $e');
    }
  }

  /// Add Chuck http call to calls subject
  void addHttpCall(ChuckHttpCall chuckHttpCall) {
    if (!enabled) {
      return;
    }
    assert(chuckHttpCall.request != null, "Http call request can't be null");
    assert(chuckHttpCall.response != null, "Http call response can't be null");
    addCall(chuckHttpCall);
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
      ChuckUtils.log('Error finding call with ID $requestId: $e');
      return null;
    }
  }

  /// Save all calls to file
  void saveHttpRequests(BuildContext context) {
    ChuckSaveHelper.saveCalls(context, callsSubject.value, Theme.of(context).brightness);
  }
}
