// ignore_for_file: discarded_futures

import 'dart:async';

/// Callback for phone shakes
typedef PhoneShakeCallback = Null Function();

/// ShakeDetector class for phone shake functionality
class ShakeDetector {
  ShakeDetector.waitForStart({
    this.onPhoneShake,
    this.shakeThresholdGravity = 2.7,
    this.shakeSlopTimeMS = 500,
    this.shakeCountResetTime = 3000,
  });

  ShakeDetector.autoStart({
    this.onPhoneShake,
    this.shakeThresholdGravity = 2.7,
    this.shakeSlopTimeMS = 500,
    this.shakeCountResetTime = 3000,
  });

  /// User callback for phone shake
  final PhoneShakeCallback? onPhoneShake;

  /// Shake detection threshold
  final double shakeThresholdGravity;

  /// Minimum time between shake
  final int shakeSlopTimeMS;

  /// Time before shake count resets
  final int shakeCountResetTime;

  int mShakeTimestamp = DateTime.now().millisecondsSinceEpoch;
  int mShakeCount = 0;

  /// StreamSubscription for Accelerometer events
  StreamSubscription<dynamic>? streamSubscription;

  /// Stops listening to accelerometer events
  void stopListening() {
    streamSubscription?.cancel();
    streamSubscription = null;
  }

  void dispose() {
    stopListening();
  }
}
