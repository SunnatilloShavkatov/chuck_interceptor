// ignore_for_file: cascade_invocations, unawaited_futures, discarded_futures

import 'dart:convert';
import 'dart:io';

import 'package:chuck_interceptor/chuck_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Chuck _chuck;
  late Dio _dio;
  late HttpClient _httpClient;
  final Color _primaryColor = const Color(0xffff5e57);
  final Color _buttonColor = const Color(0xff008000);

  @override
  void initState() {
    _chuck = Chuck(showInspectorOnShake: true);
    _dio = Dio(BaseOptions(followRedirects: false));
    _dio.interceptors.add(_chuck.dioInterceptor);
    _httpClient = HttpClient();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle buttonStyle = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll<Color>(_buttonColor),
      foregroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
    );
    return MaterialApp(
      themeMode: ThemeMode.light,
      theme: ThemeData(
        primaryColor: _primaryColor,
        brightness: Brightness.light,
        elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
      ),
      darkTheme: ThemeData(
        primaryColor: _primaryColor,
        brightness: Brightness.dark,
        elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
      ),
      navigatorKey: _chuck.navigatorKey,
      // Renders the floating Chuck button above the whole app. Tap it to open
      // the inspector, drag it to move it out of the way.
      builder: _chuck.builder,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Chuck HTTP Inspector - Example')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            _getTextWidget(
              'Welcome to example of Chuck Http Inspector. Click buttons below to generate sample data.',
            ),
            ElevatedButton(
              onPressed: _runDioRequests,
              style: buttonStyle,
              child: const Text('Run Dio HTTP Requests'),
            ),
            ElevatedButton(
              onPressed: _runHttpHttpClientRequests,
              style: buttonStyle,
              child: const Text('Run HttpClient Requests'),
            ),
            const SizedBox(height: 24),
            _getTextWidget(
              'After clicking on buttons above, the floating Chuck button in the corner'
              ' shows the number of intercepted calls. Tap it to open the inspector,'
              ' drag it to move it. You can also shake your device or click button below.',
            ),
            ElevatedButton(
              onPressed: _runGenericClientRequests,
              style: buttonStyle,
              child: const Text('Run Generic (any client) Requests'),
            ),
            ElevatedButton(
              onPressed: _runHttpInspector,
              style: buttonStyle,
              child: const Text('Run HTTP Inspector'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getTextWidget(String text) => Text(
    text,
    style: const TextStyle(fontSize: 14),
    textAlign: TextAlign.center,
  );

  Future<void> _runDioRequests() async {
    final Map<String, dynamic> body = <String, dynamic>{
      'title': 'foo',
      'body': 'bar',
      'userId': '1',
    };
    _dio.get<void>(
      'https://httpbin.org/redirect-to?url=https%3A%2F%2Fhttpbin.org',
    );
    _dio.delete<void>('https://httpbin.org/status/500');
    _dio.delete<void>('https://httpbin.org/status/400');
    _dio.delete<void>('https://httpbin.org/status/300');
    _dio.delete<void>('https://httpbin.org/status/200');
    _dio.delete<void>('https://httpbin.org/status/100');
    _dio.post<void>('https://jsonplaceholder.typicode.com/posts', data: body);
    _dio.get<void>(
      'https://jsonplaceholder.typicode.com/posts',
      queryParameters: <String, dynamic>{'test': 1},
    );
    _dio.put<void>('https://jsonplaceholder.typicode.com/posts/1', data: body);
    _dio.put<void>('https://jsonplaceholder.typicode.com/posts/1', data: body);
    _dio.delete<void>('https://jsonplaceholder.typicode.com/posts/1');
    _dio.get<void>('http://jsonplaceholder.typicode.com/test/test');

    _dio.get<void>('https://jsonplaceholder.typicode.com/photos');
    _dio.get<void>(
      'https://icons.iconarchive.com/icons/paomedia/small-n-flat/256/sign-info-icon.png',
    );
    _dio.get<void>(
      'https://images.unsplash.com/photo-1542736705-53f0131d1e98?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&w=1000&q=80',
    );
    _dio.get<void>(
      'https://findicons.com/files/icons/1322/world_of_aqua_5/128/bluetooth.png',
    );
    _dio.get<void>(
      'https://upload.wikimedia.org/wikipedia/commons/4/4e/Pleiades_large.jpg',
    );
    _dio.get<void>('http://techslides.com/demos/sample-videos/small.mp4');

    _dio.get<void>('https://www.cse.wustl.edu/~jain/cis677-97/ftp/e_3dlc2.pdf');

    final directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/test.txt');
    file.create();
    file.writeAsStringSync('123456789');

    final String fileName = file.path.split('/').last;
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    _dio.post<void>(
      'https://jsonplaceholder.typicode.com/photos',
      data: formData,
    );

    _dio.get<void>('http://dummy.restapiexample.com/api/v1/employees');
  }

  void _runHttpHttpClientRequests() {
    final Map<String, dynamic> body = <String, dynamic>{
      'title': 'foo',
      'body': 'bar',
      'userId': '1',
    };
    _httpClient
        .getUrl(Uri.parse('https://jsonplaceholder.typicode.com/posts'))
        .interceptWithChuck(_chuck);

    _httpClient
        .postUrl(Uri.parse('https://jsonplaceholder.typicode.com/posts'))
        .interceptWithChuck(_chuck, body: body, headers: <String, dynamic>{});

    _httpClient
        .putUrl(Uri.parse('https://jsonplaceholder.typicode.com/posts/1'))
        .interceptWithChuck(_chuck, body: body);

    _httpClient
        .getUrl(Uri.parse('https://jsonplaceholder.typicode.com/test/test/'))
        .interceptWithChuck(_chuck);

    _httpClient
        .postUrl(Uri.parse('https://jsonplaceholder.typicode.com/posts'))
        .then((request) async {
          _chuck.onHttpClientRequest(request, body: body);
          request.write(body);
          final httpResponse = await request.close();
          final responseBody = await utf8.decoder.bind(httpResponse).join();
          _chuck.onHttpClientResponse(
            httpResponse,
            request,
            body: responseBody,
          );
        });

    _httpClient
        .putUrl(Uri.parse('https://jsonplaceholder.typicode.com/posts/1'))
        .then((request) async {
          _chuck.onHttpClientRequest(request, body: body);
          request.write(body);
          final httpResponse = await request.close();
          final responseBody = await utf8.decoder.bind(httpResponse).join();
          _chuck.onHttpClientResponse(
            httpResponse,
            request,
            body: responseBody,
          );
        });

    _httpClient
        .patchUrl(Uri.parse('https://jsonplaceholder.typicode.com/posts/1'))
        .then((request) async {
          _chuck.onHttpClientRequest(request, body: body);
          request.write(body);
          final httpResponse = await request.close();
          final responseBody = await utf8.decoder.bind(httpResponse).join();
          _chuck.onHttpClientResponse(
            httpResponse,
            request,
            body: responseBody,
          );
        });

    _httpClient
        .deleteUrl(Uri.parse('https://jsonplaceholder.typicode.com/posts/1'))
        .then((request) async {
          _chuck.onHttpClientRequest(request);
          final httpResponse = await request.close();
          final responseBody = await utf8.decoder.bind(httpResponse).join();
          _chuck.onHttpClientResponse(
            httpResponse,
            request,
            body: responseBody,
          );
        });

    _httpClient
        .getUrl(Uri.parse('https://jsonplaceholder.typicode.com/test/test/'))
        .then((request) async {
          _chuck.onHttpClientRequest(request);
          final httpResponse = await request.close();
          final responseBody = await utf8.decoder.bind(httpResponse).join();
          _chuck.onHttpClientResponse(
            httpResponse,
            request,
            body: responseBody,
          );
        });
  }

  /// Shows the client agnostic API. Chuck only needs plain values, so the same
  /// calls work for `package:http`, chopper, retrofit or a custom client -
  /// without Chuck depending on any of them.
  Future<void> _runGenericClientRequests() async {
    // 1. Finished call: log request and response in one step.
    final uri = Uri.parse('https://jsonplaceholder.typicode.com/posts?_limit=2');
    final request = await _httpClient.getUrl(uri);
    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();

    _chuck.logHttpCall(
      method: 'GET',
      uri: uri,
      statusCode: response.statusCode,
      requestHeaders: <String, dynamic>{'accept': 'application/json'},
      responseHeaders: <String, String>{
        'content-type': response.headers.contentType?.toString() ?? '',
      },
      responseBody: responseBody,
      client: 'Generic (one step)',
    );

    // 2. Streamed call: log the request first, complete it once it resolves.
    final postUri = Uri.parse('https://jsonplaceholder.typicode.com/posts');
    final postBody = '{"title":"foo","body":"bar","userId":1}';
    final callId = _chuck.logRequest(
      method: 'POST',
      uri: postUri,
      headers: <String, dynamic>{'content-type': 'application/json'},
      body: postBody,
      client: 'Generic (streamed)',
    );

    try {
      final postRequest = await _httpClient.postUrl(postUri);
      postRequest.write(postBody);
      final postResponse = await postRequest.close();
      final postResponseBody = await utf8.decoder.bind(postResponse).join();

      _chuck.logResponse(
        callId,
        statusCode: postResponse.statusCode,
        headers: <String, String>{
          'content-type': postResponse.headers.contentType?.toString() ?? '',
        },
        body: postResponseBody,
      );
    } catch (error, stackTrace) {
      _chuck.logError(callId, error, stackTrace: stackTrace);
    }
  }

  void _runHttpInspector() {
    _chuck.showInspector();
  }
}
