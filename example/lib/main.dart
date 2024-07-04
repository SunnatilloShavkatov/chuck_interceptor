import 'dart:convert';
import 'dart:io';
import 'package:chuck_interceptor/chuck.dart';
import 'package:chuck_interceptor/core/chuck_http_client_extensions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
    _chuck = Chuck(
      showNotification: true,
      showInspectorOnShake: true,
      darkTheme: false,
      maxCallsCount: 1000,
    );
    _dio = Dio(BaseOptions(followRedirects: false));
    _dio.interceptors.add(_chuck.getDioInterceptor());
    _httpClient = HttpClient();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ButtonStyle buttonStyle = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll<Color>(_buttonColor),
      foregroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
    );
    return MaterialApp(
      theme: ThemeData(primaryColor: _primaryColor),
      navigatorKey: _chuck.getNavigatorKey(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Chuck HTTP Inspector - Example'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            _getTextWidget(
              "Welcome to example of Chuck Http Inspector. Click buttons below to generate sample data.",
            ),
            ElevatedButton(
              onPressed: _runDioRequests,
              style: buttonStyle,
              child: const Text("Run Dio HTTP Requests"),
            ),
            ElevatedButton(
              onPressed: _runHttpHttpClientRequests,
              style: buttonStyle,
              child: const Text("Run HttpClient Requests"),
            ),
            const SizedBox(height: 24),
            _getTextWidget(
              "After clicking on buttons above, you should receive notification."
              " Click on it to show inspector. You can also shake your device or click button below.",
            ),
            ElevatedButton(
              onPressed: _runHttpInspector,
              style: buttonStyle,
              child: const Text("Run HTTP Inspector"),
            )
          ],
        ),
      ),
    );
  }

  Widget _getTextWidget(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14),
      textAlign: TextAlign.center,
    );
  }

  void _runDioRequests() async {
    Map<String, dynamic> body = <String, dynamic>{
      "title": "foo",
      "body": "bar",
      "userId": "1"
    };
    _dio.get<void>(
        "https://httpbin.org/redirect-to?url=https%3A%2F%2Fhttpbin.org");
    _dio.delete<void>("https://httpbin.org/status/500");
    _dio.delete<void>("https://httpbin.org/status/400");
    _dio.delete<void>("https://httpbin.org/status/300");
    _dio.delete<void>("https://httpbin.org/status/200");
    _dio.delete<void>("https://httpbin.org/status/100");
    _dio.post<void>("https://jsonplaceholder.typicode.com/posts", data: body);
    _dio.get<void>("https://jsonplaceholder.typicode.com/posts",
        queryParameters: <String, dynamic>{"test": 1});
    _dio.put<void>("https://jsonplaceholder.typicode.com/posts/1", data: body);
    _dio.put<void>("https://jsonplaceholder.typicode.com/posts/1", data: body);
    _dio.delete<void>("https://jsonplaceholder.typicode.com/posts/1");
    _dio.get<void>("http://jsonplaceholder.typicode.com/test/test");

    _dio.get<void>("https://jsonplaceholder.typicode.com/photos");
    _dio.get<void>(
        "https://icons.iconarchive.com/icons/paomedia/small-n-flat/256/sign-info-icon.png");
    _dio.get<void>(
        "https://images.unsplash.com/photo-1542736705-53f0131d1e98?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&w=1000&q=80");
    _dio.get<void>(
        "https://findicons.com/files/icons/1322/world_of_aqua_5/128/bluetooth.png");
    _dio.get<void>(
        "https://upload.wikimedia.org/wikipedia/commons/4/4e/Pleiades_large.jpg");
    _dio.get<void>("http://techslides.com/demos/sample-videos/small.mp4");

    _dio.get<void>("https://www.cse.wustl.edu/~jain/cis677-97/ftp/e_3dlc2.pdf");

    final directory = await getApplicationDocumentsDirectory();
    File file = File("${directory.path}/test.txt");
    file.create();
    file.writeAsStringSync("123456789");

    String fileName = file.path.split('/').last;
    FormData formData = FormData.fromMap(<String, dynamic>{
      "file": await MultipartFile.fromFile(file.path, filename: fileName),
    });
    _dio.post<void>("https://jsonplaceholder.typicode.com/photos",
        data: formData);

    _dio.get<void>("http://dummy.restapiexample.com/api/v1/employees");
  }

  void _runHttpHttpClientRequests() {
    Map<String, dynamic> body = <String, dynamic>{
      "title": "foo",
      "body": "bar",
      "userId": "1"
    };
    _httpClient
        .getUrl(Uri.parse("https://jsonplaceholder.typicode.com/posts"))
        .interceptWithChuck(_chuck);

    _httpClient
        .postUrl(Uri.parse("https://jsonplaceholder.typicode.com/posts"))
        .interceptWithChuck(_chuck, body: body, headers: <String, dynamic>{});

    _httpClient
        .putUrl(Uri.parse("https://jsonplaceholder.typicode.com/posts/1"))
        .interceptWithChuck(_chuck, body: body);

    _httpClient
        .getUrl(Uri.parse("https://jsonplaceholder.typicode.com/test/test/"))
        .interceptWithChuck(_chuck);

    _httpClient
        .postUrl(Uri.parse("https://jsonplaceholder.typicode.com/posts"))
        .then((request) async {
      _chuck.onHttpClientRequest(request, body: body);
      request.write(body);
      var httpResponse = await request.close();
      var responseBody = await utf8.decoder.bind(httpResponse).join();
      _chuck.onHttpClientResponse(httpResponse, request, body: responseBody);
    });

    _httpClient
        .putUrl(Uri.parse("https://jsonplaceholder.typicode.com/posts/1"))
        .then((request) async {
      _chuck.onHttpClientRequest(request, body: body);
      request.write(body);
      var httpResponse = await request.close();
      var responseBody = await utf8.decoder.bind(httpResponse).join();
      _chuck.onHttpClientResponse(httpResponse, request, body: responseBody);
    });

    _httpClient
        .patchUrl(Uri.parse("https://jsonplaceholder.typicode.com/posts/1"))
        .then((request) async {
      _chuck.onHttpClientRequest(request, body: body);
      request.write(body);
      var httpResponse = await request.close();
      var responseBody = await utf8.decoder.bind(httpResponse).join();
      _chuck.onHttpClientResponse(httpResponse, request, body: responseBody);
    });

    _httpClient
        .deleteUrl(Uri.parse("https://jsonplaceholder.typicode.com/posts/1"))
        .then((request) async {
      _chuck.onHttpClientRequest(request);
      var httpResponse = await request.close();
      var responseBody = await utf8.decoder.bind(httpResponse).join();
      _chuck.onHttpClientResponse(httpResponse, request, body: responseBody);
    });

    _httpClient
        .getUrl(Uri.parse("https://jsonplaceholder.typicode.com/test/test/"))
        .then(
      (request) async {
        _chuck.onHttpClientRequest(request);
        var httpResponse = await request.close();
        var responseBody = await utf8.decoder.bind(httpResponse).join();
        _chuck.onHttpClientResponse(httpResponse, request, body: responseBody);
      },
    );
  }

  void _runHttpInspector() {
    _chuck.showInspector();
  }
}
