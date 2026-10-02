
# Chuck

ChuckInterceptor is an HTTP Inspector tool for Flutter which helps debugging http requests. It catches and stores http requests and responses, which can be viewed via simple UI. It is inspired from [Chuck](https://github.com/jgilfelt/chuck) and [Chucker](https://github.com/ChuckerTeam/chucker).

**Supported Dart http client plugins:**

- Dio
- HttpClient from dart:io package
- Any other client (http/http package, chopper, retrofit, ...) through the client agnostic API

**Features:**  
✔️ Detailed logs for each HTTP calls (HTTP Request, HTTP Response)  
✔️ Inspector UI for viewing HTTP calls  
✔️ Save HTTP calls to file  
✔️ Statistics  
✔️ Support for top used HTTP clients in Dart  
✔️ Error handling  
✔️ Shake or floating button to open inspector  
✔️ HTTP calls search

## Install

1. This branch is not published to pub.dev. Add it from git, pinned to a tag:

```yaml
dependencies:
  chuck_interceptor:
    git:
      url: https://github.com/SunnatilloShavkatov/chuck_interceptor.git
      ref: b.3.1.0
```

2. Install it

```bash
$ flutter pub get
```

3. Import it

```dart
import 'package:chuck_interceptor/chuck.dart';
```

## Usage
### Chuck configuration
1. Create chuck instance:

```dart
Chuck chuck = Chuck();
```

2. Add navigator key to your application:

```dart
MaterialApp( navigatorKey: chuck.getNavigatorKey(), home: ...)
```

You need to add this navigator key in order to show inspector UI.
You can use also your navigator key in Chuck:

```dart
Chuck chuck = Chuck(navigatorKey: yourNavigatorKeyHere);
```

If you need to pass navigatorKey lazily, you can use:
```dart
chuck.setNavigatorKey(yourNavigatorKeyHere);
```
This is minimal configuration required to run Chuck. Can set optional settings in Chuck constructor, which are presented below. If you don't want to change anything, you can move to Http clients configuration.

### Additional settings

You can set `showInspectorOnShake` in Chuck constructor to open inspector by shaking your device (default disabled):

```dart
Chuck chuck = Chuck(..., showInspectorOnShake: true);
```

If you want to use dark mode just add `darkTheme` flag:

```dart
Chuck chuck = Chuck(..., darkTheme: true);
```

If you want to limit max numbers of HTTP calls saved in memory, you may use `maxCallsCount` parameter.

```dart
Chuck chuck = Chuck(..., maxCallsCount: 1000));
```


If you want to change the Directionality of Chuck, you can use the `directionality` parameter. If the parameter is set to null, the Directionality of the app will be used.
```dart
Chuck chuck = Chuck(..., directionality: TextDirection.ltr);
```

App name and version written at the top of a shared or saved log. Both are optional; a row is left out
when its value is null:

```dart
Chuck chuck = Chuck(..., appName: 'MyApp', appVersion: '1.2.3+45');
```

The share button on the call details screen copies the log to the clipboard by default. Pass `onShare`
to handle it yourself, e.g. with `share_plus` added to **your** app:

```dart
Chuck chuck = Chuck(
  ...,
  onShare: (text) => SharePlus.instance.share(ShareParams(text: text)),
);
```
### HTTP Client configuration
If you're using Dio, you just need to add interceptor.

```dart
Dio dio = Dio();
dio.interceptors.add(chuck.getDioInterceptor());
```


If you're using HttpClient from dart:io package:

```dart
httpClient
	.getUrl(Uri.parse("https://jsonplaceholder.typicode.com/posts"))
	.then((request) async {
		Chuck.onHttpClientRequest(request);
		var httpResponse = await request.close();
		var responseBody = await httpResponse.transform(utf8.decoder).join();
		chuck.onHttpClientResponse(httpResponse, request, body: responseBody);
 });
```

Chuck doesn't depend on http/http package. If you're using it (or any other client), log the call
with plain values:

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

For clients where the response arrives later, log the request first and complete it by id:

```dart
final id = chuck.logRequest(method: 'POST', uri: uri, headers: headers, body: body);
// ...
chuck.logResponse(id, statusCode: 201, headers: responseHeaders, body: responseBody);
// or, if it failed:
chuck.logError(id, error, stackTrace: stackTrace);
```

If you're using Chopper. you need to add interceptor:

```dart
chopper = ChopperClient(
    interceptors: chuck.getChopperInterceptor(),
);
```

If you have other HTTP client you can use generic http call interface:
```dart
ChuckHttpCall chuckHttpCall = ChuckHttpCall(id);
chuck.addHttpCall(ChuckHttpCall);
```

## Show inspector manually

Floating, draggable button with a call counter, rendered above your whole app:

```dart
MaterialApp(
  navigatorKey: chuck.getNavigatorKey(),
  builder: chuck.builder,
  home: ...,
)
```

Use `ChuckButton` directly (`import 'package:chuck_interceptor/ui/widget/chuck_button.dart';`) for options
(`visible`, `alignment`, `padding`, `draggable`, `hideWhenEmpty`).

Or open it from your own code:

```dart
chuck.showInspector();
```

## Migration to 3.1.0

* `share_plus` and `package_info_plus` are no longer dependencies of Chuck.
  * Sharing a call copies the log to the clipboard. To keep the share sheet, add `share_plus` to your app
    and pass `onShare` (see *Additional settings*).
  * The log header no longer reads package info. Pass `appName` / `appVersion` to keep those rows.
    `Package` and `Build number` rows are gone; put the build into `appVersion` if you need it.
* `http` (`package:http`) support moved to the client agnostic API. `chuck.onHttpResponse(response)` and
  `Future<Response>.interceptWithChuck(...)` are removed; use `chuck.logHttpCall(...)` instead (see
  *HTTP Client configuration*).
* Notifications were already removed in 3.0.0. Open the inspector with `builder: chuck.builder`, shake, or
  `chuck.showInspector()`. No notification permission is needed.

## Saving calls

Chuck supports saving logs to your app's storage directory. No extra permissions are required.

## Extensions
You can use extensions to shorten your HttpClient code. This is optional, but may improve your codebase.
Example:
1. Import:
```dart
import 'package:chuck_interceptor/core/chuck_http_client_extensions.dart';
```

2. Use extensions:
```dart
httpClient
    .postUrl(Uri.parse("https://jsonplaceholder.typicode.com/posts"))
    .interceptWithChuck(chuck, body: body, headers: Map());
```


## Example
See complete example here: https://github.com/SunnatilloShavkatov/chuck_interceptor/blob/master/example/lib/main.dart
To run project, you need to call this command in your terminal:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

<p align="center">
 <img width="250px" src="https://github.com/SunnatilloShavkatov/chuck_interceptor/blob/master/media/13.jpg">
<p align="center">
