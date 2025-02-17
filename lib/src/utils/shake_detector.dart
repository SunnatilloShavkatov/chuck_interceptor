///Code from https://github.com/deven98/shake
///Seems to be not maintained for almost 2 years... (01.03.2021).
import 'dart:async';

/// Callback for phone shakes
typedef PhoneShakeCallback = Null Function();

/// ShakeDetector class for phone shake functionality
class ShakeDetector {
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

  /// This constructor waits until [startListening] is called
  ShakeDetector.waitForStart({
    this.onPhoneShake,
    this.shakeThresholdGravity = 2.7,
    this.shakeSlopTimeMS = 500,
    this.shakeCountResetTime = 3000,
  });

  /// This constructor automatically calls [startListening] and starts detection and callbacks.\
  ShakeDetector.autoStart({
    this.onPhoneShake,
    this.shakeThresholdGravity = 2.7,
    this.shakeSlopTimeMS = 500,
    this.shakeCountResetTime = 3000,
  }) {
    // startListening();
  }

  /// Stops listening to accelerometer events
  void stopListening() {
    if (streamSubscription != null) {
      streamSubscription!.cancel();
    }
  }

  void dispose() {
    streamSubscription?.cancel();
  }
}
