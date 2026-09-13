# Chuck Interceptor - AI Agent Guide
## Project Overview
Chuck Interceptor is a Flutter/Dart package for HTTP request/response inspection. It intercepts HTTP traffic from multiple client libraries (Dio, HttpClient, or any other client via the generic adapter) and presents it in a debug UI with notifications, shake detection, and file export capabilities.
## Architecture
### Core Components
- **ChuckCore** (`lib/src/core/chuck_core.dart`): Central state manager using RxDart's `BehaviorSubject<List<ChuckHttpCall>>` for reactive updates. Handles notifications, shake detection, navigation, and FIFO memory management (default 1000 calls).
- **Chuck** (`lib/chuck_interceptor.dart`): Public API facade. Initializes ChuckCore and HTTP client adapters. Must receive a `GlobalKey<NavigatorState>` to push inspector UI routes.
- **Adapters**: Translate HTTP client-specific formats into `ChuckHttpCall` objects:
  - `ChuckDioInterceptor` extends Dio's `InterceptorsWrapper`
  - `ChuckHttpClientAdapter` handles dart:io `HttpClient`
  - `ChuckGenericAdapter` (`lib/src/core/chuck_generic_adapter.dart`) is client agnostic: it builds calls from plain values (method, uri, headers, body, status code), so `package:http`, chopper, retrofit or custom clients work without Chuck depending on them. Ids it generates count down from `-1` to avoid colliding with `hashCode` based ids.
### Request/Response Flow
1. HTTP client adapter creates `ChuckHttpCall(requestId)` using `hashCode` as unique ID
2. Request details populate `ChuckHttpRequest`, call added to `ChuckCore.callsSubject`
3. Response/error updates matched by request ID using `_selectCall(requestId)`
4. UI screens subscribe to `callsSubject` stream for automatic updates
5. When maxCallsCount exceeded, oldest call (by `createdTime`) is replaced
### Data Models
- **ChuckHttpCall**: Container with `id`, `method`, `endpoint`, `server`, `duration`, `loading` state, `request`, `response`, `error`. Incl- **ChuckHttpCall**: Container with `id`, `method`, `endpoint`, `server`, `duration`, `loading` state, `request`, `response`, `error`. Incl- **ChuckHttpCall**: Container with `id`UI Layer
- **ChuckCallsListScreen**: Main list with search (comma-separated terms, `!` ex- **ChuckCallsListScreen**: Main list with search (comma-sesave
- **ChuckCallDetailsScreen**: Request/response details with tabs
- **Widgets**: Reusable components in `lib/src/ui/widget/`
## Development Workflows
### Running the Example App
```bash
cd example
flutter run
# The example demonstrates the supported HTTP client integrations
```
### Testing
```bash
flutter test
# Core tests in test/chuck_core_test.dart validate:
# - Call addition/removal
# - FIFO memory management
# - Response correlation
# - Curl command generation
```
### Publishing (Maintainers)
```bash
# Version bump in pubspec.yaml and # Version bumflutter pub publish --dry-run
flutter pub publish
```
## Key Patterns & Conventions
### Request/Response Correlation
All adapters use `object.hashCode` as request ID. For `HttpClientRequest` and Dio's `RequestOptions`, this ensures reliable matching between request/response even with concurrent calls.
### Memory Management
`ChuckCore.addCall()` enforces `maxCallsCount` limit by finding and replacing the oldest call (by `createdTime`). Creates new list instances to trigger BehaviorSubject updates: `callsSubject.add([...currentCalls, call])`.
### Error Handling Philosophy
Recent improvements (Recent improvements - Try-catch blocks with `ChuckUtils.log()Recent in-cRecent ierrors
- Graceful degradation (e.g., `_selectCall()` returns null,- Gracefuws)
- Defensive null checks before operations
### Null Safety
All models use nullable types for request/response data. UI widgetsAll models u `null` gracefully. Example: `call.response?.All models use nullable tyance OptimiAll models use nullable types for request/response data. UI widgetsAll mod- Cache extent configured onAll models use nullable typ- Immutable list copies for BehaviorAll models use nullable types for request/response data. UI widgetsAll models u `null` gracefully. Example: `call.response?.All models use nullable tyance OptimiAll models use nullableChAll models use null;
MaterialApp(navigatorKey: chuck.navigatorKey, ...)
// OR lazy set:
chuck.setNavigatorKey(yourKey);
```
### Dio Integration
```dart
Dio dio = Dio();
dio.interceptors.add(chuck.dioInterceptor);
```
Interceptor hooks: `onRequest()`, `onResponse()`, `onError()`. FormData fields/files handled specially.
### HttpClient Integration
Two approaches:
1. Extension method: `request.interceptWithChuck(chuck, body: ...)`
2. Manual: `chuck.onHttpClientRequest(request)` → `chuck.onHttpClientResponse(response, request, body: ...)`
### Generic (any client) Integration
```dart
// finished call, one step
chuck.logHttpCall(method: 'GET', uri: uri, statusCode: 200, responseBody: body);
// streaming: request first, response/error later
final id = chuck.logRequest(method: 'POST', uri: uri, body: payload);
chuck.logResponse(id, statusCode: 201, headers: headers, body: body);
chuck.logError(id, error, stackTrace: stackTrace);
```
### Floating Button
`ChuckButton` (in `lib/src/ui/widget/chuck_button.dart`) is a draggable overlay bubble rendered through `MaterialApp.builder` (`chuck.builder`). It listens to `ChuckCore.callsStream`, shows total call count, colours itself by traffic state (idle/in-flight/failed) and opens the inspector on tap. No native notification dependency is used anymore.
### Shake Detection
`ShakeDetector` (in `lib/src/utils/shake_detector.dart`) uses accelerometer. Only works on physical devices with sensors. Threshold: 5G by default.
## Common Gotchas
- **No calls appearing**: Ensure navigat- **No calls  before making requests. Check `ChuckUtils.log()` console output.
- **Dio FormData**- **Dio FormData**- **Dio FormData**- **Dl fields/files in separate properties.
- **HttpClient body**: Must manually read response stream to pass to `onHttpClientResponse()`. Example app shows pattern.
- **Concurrent requests**: Hash-based IDs may collide in rare cases; consider using atomic counters if issues arise.
- **Dispose**: Call `chuck.dispose()` to clean up streams/subscriptions when done.
## File Organization
```
lib/src/
├── core/           # ChuckCore, adapters, interceptors
├── model/          # Data classes (ChuckHttpCall, etc.)
├── ui/
│   ├── page/       # Full-screen views
│   └── widget/     # Reusable UI components
├── helper/         # Alert, conversion, copy, save utilities
└── utils/          # Constants, parser, shake detector
```
## Testing Strategy
Focus on unit tests for `ChuckCore` logic (call management, FIFO limits, response correlation). UI tests avoided due to navigator/notification dependencies. Mock ChuckCore for adapter tests if needed.
---
*Last updated: 2026-04-29 | Version: 2.5.0*
