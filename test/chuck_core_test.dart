import 'package:chuck_interceptor/src/core/chuck_core.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/model/chuck_http_error.dart';
import 'package:chuck_interceptor/src/model/chuck_http_request.dart';
import 'package:chuck_interceptor/src/model/chuck_http_response.dart';
import 'package:chuck_interceptor/src/theme/chuck_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('ChuckCore Tests', () {
    late ChuckCore chuckCore;

    setUp(() {
      chuckCore = ChuckCore(
        GlobalKey<NavigatorState>(),
        showInspectorOnShake: false,
        maxCallsCount: 5, // Small limit for testing
      );
    });

    tearDown(() {
      chuckCore.dispose();
    });

    test('should initialize with empty calls list', () {
      expect(chuckCore.callsSubject.value, isEmpty);
    });

    test('should add HTTP call successfully', () {
      // Arrange
      final call = ChuckHttpCall(1)
        ..method = 'GET'
        ..endpoint = '/test'
        ..server = 'example.com'
        ..request = ChuckHttpRequest()
        ..response = ChuckHttpResponse();

      // Act
      chuckCore.addCall(call);

      // Assert
      expect(chuckCore.callsSubject.value.length, equals(1));
      expect(chuckCore.callsSubject.value.first.id, equals(1));
      expect(chuckCore.callsSubject.value.first.method, equals('GET'));
    });

    test('should respect maxCallsCount limit', () {
      // Arrange & Act
      for (int i = 0; i < 7; i++) {
        final call = ChuckHttpCall(i)
          ..method = 'GET'
          ..endpoint = '/test$i'
          ..server = 'example.com'
          ..request = ChuckHttpRequest()
          ..response = ChuckHttpResponse();
        chuckCore.addCall(call);
      }

      // Assert
      expect(chuckCore.callsSubject.value.length, equals(5));
      // Should contain the 5 most recent calls (2, 3, 4, 5, 6)
      final callIds = chuckCore.callsSubject.value
          .map((call) => call.id)
          .toList();
      expect(callIds, containsAll([2, 3, 4, 5, 6]));
      expect(callIds, isNot(contains(0))); // Oldest call should be removed
    });

    test('should add response to existing call', () {
      // Arrange
      final call = ChuckHttpCall(1)
        ..method = 'GET'
        ..endpoint = '/test'
        ..server = 'example.com'
        ..request = ChuckHttpRequest()
        ..response = ChuckHttpResponse();
      chuckCore.addCall(call);

      final response = ChuckHttpResponse()
        ..status = 200
        ..time = DateTime.now();

      // Act
      chuckCore.addResponse(response, 1);

      // Assert
      final updatedCall = chuckCore.callsSubject.value.first;
      expect(updatedCall.response?.status, equals(200));
      expect(updatedCall.loading, isFalse);
      expect(updatedCall.duration, greaterThanOrEqualTo(0));
    });

    test('should handle non-existent call gracefully', () {
      // Arrange
      final response = ChuckHttpResponse()..status = 200;

      // Act & Assert - should not throw
      expect(() => chuckCore.addResponse(response, 999), returnsNormally);
    });

    test('should add error to existing call', () {
      // Arrange
      final call = ChuckHttpCall(1)
        ..method = 'GET'
        ..endpoint = '/test'
        ..server = 'example.com'
        ..request = ChuckHttpRequest()
        ..response = ChuckHttpResponse();
      chuckCore.addCall(call);

      // Act
      final error = ChuckHttpError<Exception>(
        error: Exception('Network timeout'),
      );
      chuckCore.addError(error, 1);

      // Assert
      final updatedCall = chuckCore.callsSubject.value.first;
      expect(updatedCall.error, isNotNull);
      expect(updatedCall.loading, isFalse);
    });

    test('should not record calls when enabled is false', () {
      // Arrange
      final disabledCore = ChuckCore(
        GlobalKey<NavigatorState>(),
        enabled: false,
        showInspectorOnShake: false,
        maxCallsCount: 10,
      );

      final call = ChuckHttpCall(42)
        ..method = 'GET'
        ..endpoint = '/disabled';

      // Act
      disabledCore.addCall(call);

      // Assert
      expect(disabledCore.callsSubject.value, isEmpty);

      disabledCore.dispose();
    });

    test('should maintain FIFO order when exceeding maxCallsCount', () {
      final limitedCore = ChuckCore(
        GlobalKey<NavigatorState>(),
        showInspectorOnShake: false,
        maxCallsCount: 3,
      );

      for (int i = 1; i <= 5; i++) {
        limitedCore.addCall(ChuckHttpCall(i)..endpoint = '/call$i');
      }

      expect(limitedCore.callsSubject.value.length, equals(3));
      expect(
        limitedCore.callsSubject.value.map((c) => c.id).toList(),
        equals([3, 4, 5]),
      );

      limitedCore.dispose();
    });

    test('should clear all calls', () {
      // Arrange
      final call = ChuckHttpCall(1)
        ..method = 'GET'
        ..endpoint = '/test'
        ..server = 'example.com'
        ..request = ChuckHttpRequest()
        ..response = ChuckHttpResponse();
      chuckCore
        ..addCall(call)
        // Act
        ..removeCalls();

      // Assert
      expect(chuckCore.callsSubject.value, isEmpty);
    });
  });

  group('ChuckHttpCall Tests', () {
    test('should create call with correct initial values', () {
      // Arrange & Act
      final call = ChuckHttpCall(123);

      // Assert
      expect(call.id, equals(123));
      expect(call.loading, isTrue);
      expect(call.createdTime, isA<DateTime>());
      expect(call.method, isEmpty);
      expect(call.endpoint, isEmpty);
      expect(call.server, isEmpty);
      expect(call.secure, isFalse);
      expect(call.duration, equals(0));
    });

    test('should generate correct curl command', () {
      // Arrange
      final call = ChuckHttpCall(1)
        ..method = 'POST'
        ..endpoint = '/api/test'
        ..server = 'example.com'
        ..secure = true;

      final request = ChuckHttpRequest()
        ..headers = {'Content-Type': 'application/json'}
        ..body = '{"test": "data"}'
        ..queryParameters = {'param1': 'value1'};
      call.request = request;

      // Act
      final curlCommand = call.getCurlCommand();

      // Assert
      expect(curlCommand, contains('curl'));
      expect(curlCommand, contains('-X POST'));
      expect(curlCommand, contains('https://example.com/api/test'));
      expect(curlCommand, contains('Content-Type: application/json'));
      expect(curlCommand, contains('{"test": "data"}'));
      expect(curlCommand, contains('param1=value1'));
    });
  });

  group('ChuckThemeExtension Tests', () {
    test('should provide valid light and dark fallback themes', () {
      final lightTheme = ChuckThemeExtension.fallback(Brightness.light);
      final darkTheme = ChuckThemeExtension.fallback(Brightness.dark);

      expect(lightTheme, isNotNull);
      expect(darkTheme, isNotNull);
      expect(lightTheme.background, isNot(equals(darkTheme.background)));
      expect(lightTheme.methodGet, isNotNull);
      expect(darkTheme.methodPost, isNotNull);
      expect(lightTheme.jsonKeyColor, isNotNull);
      expect(lightTheme.jsonNumberColor, isNotNull);
      expect(lightTheme.jsonStringColor, isNotNull);
    });

    test('should support copyWith', () {
      const original = ChuckThemeExtension.light;
      final modified = original.copyWith(background: Colors.amber);

      expect(modified.background, equals(Colors.amber));
      expect(modified.surface, equals(original.surface));
      expect(modified.methodGet, equals(original.methodGet));
    });

    test('should support lerp interpolation', () {
      const light = ChuckThemeExtension.light;
      const dark = ChuckThemeExtension.dark;

      final mid = light.lerp(dark, 0.5);
      expect(mid, isNotNull);
      expect(mid.background, isNotNull);
    });
  });
}
