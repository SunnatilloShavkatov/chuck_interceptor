import 'package:chuck_interceptor/core/chuck_core.dart';
import 'package:chuck_interceptor/core/chuck_generic_adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChuckGenericAdapter Tests', () {
    late ChuckCore chuckCore;
    late ChuckGenericAdapter adapter;

    setUp(() {
      chuckCore = ChuckCore(
        GlobalKey<NavigatorState>(),
        showInspectorOnShake: false,
        darkTheme: false,
        maxCallsCount: 10,
      );
      adapter = ChuckGenericAdapter(chuckCore);
    });

    tearDown(() {
      chuckCore.dispose();
    });

    test('should log a finished call in one step', () {
      final id = adapter.onCall(
        method: 'get',
        uri: Uri.parse('https://example.com/posts?page=2'),
        statusCode: 200,
        requestHeaders: {'Content-Type': 'application/json'},
        responseHeaders: {'content-length': '2'},
        responseBody: '[]',
        duration: const Duration(milliseconds: 120),
        client: 'http package',
      );

      final call = chuckCore.callsSubject.value.single;
      expect(call.id, id);
      expect(call.method, 'GET');
      expect(call.client, 'http package');
      expect(call.endpoint, '/posts');
      expect(call.server, 'example.com');
      expect(call.secure, isTrue);
      expect(call.loading, isFalse);
      expect(call.duration, 120);
      expect(call.request!.contentType, 'application/json');
      expect(call.request!.queryParameters, {'page': '2'});
      expect(call.response!.status, 200);
      expect(call.response!.body, '[]');
      expect(call.response!.size, 2);
    });

    test('should treat an empty path as root', () {
      adapter.onCall(method: 'GET', uri: Uri.parse('http://example.com'), statusCode: 204);

      final call = chuckCore.callsSubject.value.single;
      expect(call.endpoint, '/');
      expect(call.secure, isFalse);
    });

    test('should complete a streamed call with a response', () {
      final id = adapter.onRequest(method: 'POST', uri: Uri.parse('https://example.com/posts'), body: '{"a":1}');

      expect(chuckCore.callsSubject.value.single.loading, isTrue);

      adapter.onResponse(id, statusCode: 201, headers: {'x-id': '9'}, body: 'created');

      final call = chuckCore.callsSubject.value.single;
      expect(call.loading, isFalse);
      expect(call.request!.body, '{"a":1}');
      expect(call.response!.status, 201);
      expect(call.response!.headers, {'x-id': '9'});
      expect(call.response!.body, 'created');
    });

    test('should wrap a non Dio error', () {
      final id = adapter.onRequest(method: 'GET', uri: Uri.parse('https://example.com/posts'));

      adapter.onError(id, 'boom', stackTrace: StackTrace.empty);

      final error = chuckCore.callsSubject.value.single.error!.error!;
      expect(error, isA<DioException>());
      expect(error.error, 'boom');
      expect(error.message, 'boom');
    });

    test('should ignore a response for an unknown call id', () {
      adapter.onResponse(12345, statusCode: 200);

      expect(chuckCore.callsSubject.value, isEmpty);
    });

    test('should generate negative, non-colliding ids', () {
      final first = adapter.onRequest(method: 'GET', uri: Uri.parse('https://example.com/a'));
      final second = adapter.onRequest(method: 'GET', uri: Uri.parse('https://example.com/b'));

      expect(first, isNegative);
      expect(second, isNegative);
      expect(first, isNot(second));
    });

    test('should respect a caller provided id', () {
      final id = adapter.onRequest(method: 'GET', uri: Uri.parse('https://example.com/a'), id: 42);

      expect(id, 42);
      expect(chuckCore.callsSubject.value.single.id, 42);
    });
  });
}
