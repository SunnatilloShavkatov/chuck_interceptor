import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chuck_interceptor/src/core/chuck_core.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/model/chuck_http_request.dart';
import 'package:chuck_interceptor/src/model/chuck_http_response.dart';

void main() {
  group('ChuckCore Tests', () {
    late ChuckCore chuckCore;

    setUp(() {
      chuckCore = ChuckCore(
        GlobalKey<NavigatorState>(),
        showNotification: false, // Disable notifications for testing
        showInspectorOnShake: false,
        notificationIcon: "@mipmap/ic_launcher",
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
      final call = ChuckHttpCall(1);
      call.method = "GET";
      call.endpoint = "/test";
      call.server = "example.com";
      call.request = ChuckHttpRequest();
      call.response = ChuckHttpResponse();

      // Act
      chuckCore.addCall(call);

      // Assert
      expect(chuckCore.callsSubject.value.length, equals(1));
      expect(chuckCore.callsSubject.value.first.id, equals(1));
      expect(chuckCore.callsSubject.value.first.method, equals("GET"));
    });

    test('should respect maxCallsCount limit', () {
      // Arrange & Act
      for (int i = 0; i < 7; i++) {
        final call = ChuckHttpCall(i);
        call.method = "GET";
        call.endpoint = "/test$i";
        call.server = "example.com";
        call.request = ChuckHttpRequest();
        call.response = ChuckHttpResponse();
        chuckCore.addCall(call);
      }

      // Assert
      expect(chuckCore.callsSubject.value.length, equals(5));
      // Should contain the 5 most recent calls (2, 3, 4, 5, 6)
      final callIds = chuckCore.callsSubject.value.map((call) => call.id).toList();
      expect(callIds, containsAll([2, 3, 4, 5, 6]));
      expect(callIds, isNot(contains(0))); // Oldest call should be removed
    });

    test('should add response to existing call', () {
      // Arrange
      final call = ChuckHttpCall(1);
      call.method = "GET";
      call.endpoint = "/test";
      call.server = "example.com";
      call.request = ChuckHttpRequest();
      call.response = ChuckHttpResponse();
      chuckCore.addCall(call);

      final response = ChuckHttpResponse();
      response.status = 200;
      response.time = DateTime.now();

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
      final response = ChuckHttpResponse();
      response.status = 200;

      // Act & Assert - should not throw
      expect(() => chuckCore.addResponse(response, 999), returnsNormally);
    });

    test('should clear all calls', () {
      // Arrange
      final call = ChuckHttpCall(1);
      call.method = "GET";
      call.endpoint = "/test";
      call.server = "example.com";
      call.request = ChuckHttpRequest();
      call.response = ChuckHttpResponse();
      chuckCore.addCall(call);

      // Act
      chuckCore.removeCalls();

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
      final call = ChuckHttpCall(1);
      call.method = "POST";
      call.endpoint = "/api/test";
      call.server = "example.com";
      call.secure = true;

      final request = ChuckHttpRequest();
      request.headers = {"Content-Type": "application/json"};
      request.body = '{"test": "data"}';
      request.queryParameters = {"param1": "value1"};
      call.request = request;

      // Act
      final curlCommand = call.getCurlCommand();

      // Assert
      expect(curlCommand, contains("curl"));
      expect(curlCommand, contains("-X POST"));
      expect(curlCommand, contains("https://example.com/api/test"));
      expect(curlCommand, contains("Content-Type: application/json"));
      expect(curlCommand, contains('{"test": "data"}'));
      expect(curlCommand, contains("param1=value1"));
    });
  });
}
