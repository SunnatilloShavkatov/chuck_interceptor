# Chuck

<h3 align="center" style="font-size: 35px;">Need anything Flutter related? Reach out
on <a href="https://www.linkedin.com/in/sunnatillo-shavkatov-430789216/">LinkedIn</a>
</h3>

ChuckInterceptor is an HTTP Inspector tool for Flutter which helps debugging http requests. It
catches and stores http requests and responses, which can be viewed via simple UI. It is inspired
from [Chuck](https://github.com/jgilfelt/chuck)
and [Chucker](https://github.com/ChuckerTeam/chucker).

**Supported Dart http client plugins:**

- Dio
- HttpClient from dart:io package
- Any other client (`http`, `chopper`, `retrofit`, custom) via the client agnostic API

**Features:**  
✔️ Detailed logs for each HTTP calls (HTTP Request, HTTP Response)  
✔️ Inspector UI for viewing HTTP calls  
✔️ Save HTTP calls to file  
✔️ Statistics  
✔️ Floating inspector button with live call counter  
✔️ Support for top used HTTP clients in Dart  
✔️ Client agnostic API - log calls from any HTTP client, zero extra dependencies  
✔️ Enhanced error handling with comprehensive recovery  
✔️ Shake to open inspector  
✔️ HTTP calls search and filtering  
✔️ Performance optimized with memory management  
✔️ Comprehensive unit test coverage  
✔️ Curl command generation for easy debugging

## Install

1. Add this to your **pubspec.yaml** file:

```yaml
dependencies:
  chuck_interceptor: ^3.1.2
```

2. Install it

```bash
$ flutter packages get
```

3. Import it

```dart
import 'package:chuck_interceptor/chuck_interceptor.dart';
```

## Usage

### Chuck configuration

1. Create chuck instance:

```

Chuck chuck = Chuck();
```

2. Add navigator key to your application:

```
MaterialApp
(
navigatorKey: chuck.getNavigatorKey(), home: ...)
```

You need to add this navigator key in order to show inspector UI.
You can use also your navigator key in Chuck:

```

Chuck chuck = Chuck(navigatorKey: yourNavigatorKeyHere);
```

If you need to pass navigatorKey lazily, you can use:

```
chuck.setNavigatorKey(yourNavigatorKeyHere);
```

This is minimal configuration required to run Chuck. Can set optional settings in Chuck constructor,
which are presented below. If you don't want to change anything, you can move to Http clients
configuration.

### Additional settings

You can enable/disable Chuck dynamically (e.g. disable in production builds for zero overhead):
```dart
Chuck chuck = Chuck(
  enabled: kDebugMode, // Completely short-circuits in production
  maxBodySize: 1024 * 1024, // 1 MB max payload body size
);
```

You can set `showInspectorOnShake` in Chuck constructor to open inspector by shaking your device (default disabled):

```dart
Chuck chuck = Chuck(showInspectorOnShake: true);
```

If you want to use dark mode just add `darkTheme` flag:

```dart
Chuck chuck = Chuck(darkTheme: true);
```

You can also customize the entire palette using `ChuckThemeExtension`:

```dart
MaterialApp(
  theme: ThemeData.light().copyWith(
    extensions: [
      ChuckThemeExtension.light.copyWith(
        accent: Colors.deepPurple,
        methodGet: Colors.teal,
      ),
    ],
  ),
  navigatorKey: chuck.getNavigatorKey(),
  ...
);
```

If you want to limit max numbers of HTTP calls saved in memory, you may use `maxCallsCount`
parameter (default is 1000).

```dart
Chuck chuck = Chuck(maxCallsCount: 500);
```

If you want to change the Directionality of Chuck, you can use the `directionality` parameter. If
the parameter is set to null, the Directionality of the app will be used.

```dart
Chuck chuck = Chuck(directionality: TextDirection.ltr);
```

### Floating inspector button

Chuck ships with `ChuckButton` — a draggable floating bubble which shows how many HTTP calls were
intercepted and opens the inspector when tapped. It replaces the local notification used by Chuck
`2.x`, so the package no longer depends on `flutter_local_notifications` (no notification
permission, no notification channel setup, smaller binary).

The easiest way to use it is `MaterialApp.builder`:

```dart
MaterialApp(
  navigatorKey: chuck.navigatorKey,
  builder: chuck.builder,
  home: const HomeScreen(),
);
```

The bubble colour reflects the state of intercepted traffic: primary colour by default, orange while
requests are in flight, red when at least one call failed. Counts above 999 are shortened to `999+`.

If you need more control, use the widget directly:

```dart
MaterialApp(
  navigatorKey: chuck.navigatorKey,
  builder: (context, child) => ChuckButton(
    chuckCore: chuck.core,
    visible: kDebugMode,                // render the button only in debug builds
    alignment: Alignment.bottomLeft,    // start position
    padding: const EdgeInsets.all(24),  // distance from screen edges
    draggable: true,                    // allow user to move the button
    hideWhenEmpty: true,                // hide until the first call is intercepted
    child: child,
  ),
  home: const HomeScreen(),
);
```

The button is hidden automatically when Chuck is disabled (`Chuck(enabled: false)`).

If you prefer your own UI, listen to the calls stream and build whatever you want:

```dart
StreamBuilder<List<ChuckHttpCall>>(
  stream: chuck.callsStream,
  builder: (context, snapshot) => Badge(
    label: Text('${snapshot.data?.length ?? 0}'),
    child: IconButton(
      icon: const Icon(Icons.http),
      onPressed: chuck.showInspector,
    ),
  ),
);
```

### HTTP Client configuration

#### Dio

If you're using Dio, you just need to add the interceptor:

```dart
Dio dio = Dio();
dio.interceptors.add(chuck.dioInterceptor);
```

#### HttpClient (dart:io)

If you're using HttpClient from `dart:io`:

```dart
httpClient
    .getUrl(Uri.parse("https://jsonplaceholder.typicode.com/posts"))
    .then((request) async {
  chuck.onHttpClientRequest(request);
  var httpResponse = await request.close();
  var responseBody = await httpResponse.transform(utf8.decoder).join();
  chuck.onHttpClientResponse(httpResponse, request, body: responseBody);
});
```

#### Any other client (http, Chopper, Retrofit, custom)

Chuck does not depend on `package:http` or any other client. Instead it takes plain values
(method, uri, headers, body, status code), so every client can be inspected through the same API.

For a client which hands you the finished call, log it in one step:

```dart
final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));

chuck.logHttpCall(
  method: response.request!.method,
  uri: response.request!.url,
  statusCode: response.statusCode,
  requestHeaders: response.request?.headers,
  responseHeaders: response.headers,
  responseBody: response.body,
  client: 'http package',
);
```

For a client which streams the response, log the request first and complete it later:

```dart
final callId = chuck.logRequest(
  method: 'POST',
  uri: uri,
  headers: headers,
  body: requestBody,
  client: 'My client',
);

try {
  final response = await send();
  chuck.logResponse(
    callId,
    statusCode: response.statusCode,
    headers: response.headers,
    body: response.body,
  );
} catch (error, stackTrace) {
  chuck.logError(callId, error, stackTrace: stackTrace);
}
```

Bodies larger than `maxBodySize` are truncated automatically, and generated call ids never collide
with the Dio / `HttpClient` adapters.

If you'd rather build the call yourself, the raw interface is still there:

```dart
ChuckHttpCall chuckHttpCall = ChuckHttpCall(id);
chuckHttpCall.request = ChuckHttpRequest();
chuckHttpCall.response = ChuckHttpResponse();
chuck.addHttpCall(chuckHttpCall);
```

## Show inspector manually

You may need that if you won't use the floating button or shake:

```dart
chuck.showInspector();
```

## Saving and Sharing calls

Chuck supports saving and sharing HTTP call logs directly via the system share sheet (`share_plus`). No storage permissions (`WRITE_EXTERNAL_STORAGE`) are required.

## Extensions

You can use extensions to shorten your http client code:

```dart
import 'package:chuck_interceptor/chuck_interceptor.dart';

// HttpClient extension
httpClient.postUrl(Uri.parse("https://jsonplaceholder.typicode.com/posts"))
    .interceptWithChuck(chuck, body: body, headers: {});
```

## Example

See complete example
here: https://github.com/SunnatilloShavkatov/chuck_interceptor/blob/master/example/lib/main.dart
To run project, you need to call this command in your terminal:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

<p align="center">
 <img width="250px" src="https://github.com/SunnatilloShavkatov/chuck_interceptor/blob/master/media/13.jpg">
<p align="center">
