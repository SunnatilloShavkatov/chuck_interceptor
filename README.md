
# Chuck

ChuckInterceptor is an HTTP Inspector tool for Flutter which helps debugging http requests. It catches and stores http requests and responses, which can be viewed via simple UI. It is inspired from [Chuck](https://github.com/jgilfelt/chuck) and [Chucker](https://github.com/ChuckerTeam/chucker).

**Supported Dart http client plugins:**

- Dio
- HttpClient from dart:io package
- Http from http/http package

**Features:**  
✔️ Detailed logs for each HTTP calls (HTTP Request, HTTP Response)  
✔️ Inspector UI for viewing HTTP calls  
✔️ Save HTTP calls to file  
✔️ Statistics  
✔️ Notification on HTTP call  
✔️ Support for top used HTTP clients in Dart  
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
  chuck_interceptor: ^2.3.1
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
Chuck chuck = Chuck(showNotification: true, navigatorKey: yourNavigatorKeyHere);
```

If you need to pass navigatorKey lazily, you can use:
```dart
chuck.setNavigatorKey(yourNavigatorKeyHere);
```
This is minimal configuration required to run Chuck. Can set optional settings in Chuck constructor, which are presented below. If you don't want to change anything, you can move to Http clients configuration.

### Additional settings

You can set `showNotification` in Chuck constructor to show notification. Clicking on this notification will open inspector.
```dart
Chuck chuck = Chuck(..., showNotification: true);
```

You can set `showInspectorOnShake` in Chuck constructor to open inspector by shaking your device (default disabled):

```dart
Chuck chuck = Chuck(..., showInspectorOnShake: true);
```

If you want to use dark mode just add `darkTheme` flag:

```dart
Chuck chuck = Chuck(..., darkTheme: true);
```

If you want to pass another notification icon, you can use `notificationIcon` parameter. Default value is @mipmap/ic_launcher.
```dart
Chuck chuck = Chuck(..., notificationIcon: "myNotificationIconResourceName");
```

If you want to limit max numbers of HTTP calls saved in memory, you may use `maxCallsCount` parameter.

```dart
Chuck chuck = Chuck(..., maxCallsCount: 1000));
```


If you want to change the Directionality of Chuck, you can use the `directionality` parameter. If the parameter is set to null, the Directionality of the app will be used.
```dart
Chuck chuck = Chuck(..., directionality: TextDirection.ltr);
```
### HTTP Client configuration
If you're using Dio, you just need to add interceptor.

```dart
Dio dio = Dio();
dio.interceptors.add(chuck.dioInterceptor);
```


If you're using HttpClient from dart:io package:

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

If you're using http from http/http package:

```dart
http.get('https://jsonplaceholder.typicode.com/posts').then((response) {
    chuck.onHttpResponse(response);
});
```

If you're using Chopper, you can use the generic http call interface:

```dart
// Chopper integration example
final response = await chopper.get('/posts');
chuck.onHttpResponse(response);
```

If you have other HTTP client you can use generic http call interface:
```dart
ChuckHttpCall chuckHttpCall = ChuckHttpCall(id);
chuckHttpCall.request = ChuckHttpRequest();
chuckHttpCall.response = ChuckHttpResponse();
chuck.addHttpCall(chuckHttpCall);
```

## Show inspector manually

You may need that if you won't use shake or notification:

```dart
chuck.showInspector();
```

## Saving calls

Chuck supports saving logs to your mobile device storage. In order to make save feature works, you need to add in your Android application manifest:

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## Extensions
You can use extensions to shorten your http and http client code. This is optional, but may improve your codebase.
Example:
1. Import:
```dart
import 'package:chuck_interceptor/chuck_interceptor.dart';
```

2. Use extensions:
```dart
http
    .post('https://jsonplaceholder.typicode.com/posts', body: body)
    .then((response) => chuck.onHttpResponse(response, body: body));
```

```dart
httpClient
    .postUrl(Uri.parse("https://jsonplaceholder.typicode.com/posts"))
    .interceptWithChuck(chuck, body: body, headers: {});
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
