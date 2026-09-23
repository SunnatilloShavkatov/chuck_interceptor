## 3.1.1

* Bumped `material_ui` to `^1.4.0`.
* Formatted the package, example and tests with a 120 column page width (`formatter.page_width`
  in `analysis_options.yaml`). No API or behaviour changes.

## 3.1.0

* **Dropped the `http` (`package:http`) dependency**. Chuck no longer pulls `http` into consumers'
  dependency graphs.
  * Removed `Chuck.onHttpResponse(...)` and the internal `ChuckHttpAdapter`.
  * Removed the `ChuckHttpExtensions` extension (`Future<Response>.interceptWithChuck(...)`).
* **New client agnostic API** which replaces it and works with *any* http client, including
  `package:http`, `chopper`, `retrofit` or a hand written one. It takes plain values (method, uri,
  headers, body, status code), so Chuck does not need to depend on the client:
  * `chuck.logHttpCall(...)` logs a finished request and response in one step.
  * `chuck.logRequest(...)` returns a call id; `chuck.logResponse(id, ...)` and
    `chuck.logError(id, ...)` complete it later, for clients which stream the response.
  * `chuck.genericAdapter` exposes the same methods as `ChuckGenericAdapter` if you prefer wiring
    the adapter yourself.
  * Generated call ids count down from `-1`, so they never collide with the `hashCode` based ids
    used by the Dio and `HttpClient` adapters.
* Migration for `package:http` users:

  ```dart
  final response = await http.get(url);
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
* Dio and `dart:io` `HttpClient` integrations are unchanged.

## 3.0.1

* **Inspector no longer inherits the host app theme**. Chuck screens and dialogs now build their own
  `ThemeData` (`ChuckThemeData.isolate` / `ChuckThemeData.buildTheme`), so the app's colors, fonts,
  tab and button styling can't leak into the inspector. Only the brightness and an explicit
  `ChuckThemeExtension` override are still taken from the surrounding app.
* Fixed clipped tab labels ("Response") on the call details screen.
* Trimmed the published archive via `.pubignore`: package tests, the example app's test and
  analysis config, `pubspec.lock`, `.metadata` and editor/CI folders are no longer shipped to
  pub.dev (they stay in git). Only `example/lib/main.dart`, `example/pubspec.yaml` and
  `example/README.md` remain so the pub.dev "Example" tab keeps working.

## 3.0.0

* **Breaking: removed `flutter_local_notifications`**. Chuck no longer ships a native notification
  dependency, which removes the notification permission, the notification channel setup and a large
  chunk of native code from the final APK/IPA.
  * Removed `Chuck(showNotification: ...)` and `Chuck(notificationIcon: ...)` parameters — delete
    them from your `Chuck(...)` call.
  * Same for `ChuckCore(showNotification: ..., notificationIcon: ...)`.
* **New `ChuckButton`**: draggable floating button which shows the number of intercepted calls and
  opens the inspector on tap. It replaces the notification as the default way of opening Chuck.
  * Use `builder: chuck.builder` in `MaterialApp` for the default placement, or build
    `ChuckButton(chuckCore: chuck.core, child: child)` yourself to customise `visible`, `alignment`,
    `padding`, `draggable` and `hideWhenEmpty`.
  * Button color reflects traffic state (idle / in flight / failed) and it is hidden automatically
    when `enabled: false` or while the inspector is open.
* Added `Chuck.core`, `Chuck.callsStream` and `ChuckCore.callsStream` / `ChuckCore.isInspectorOpened`
  so a custom inspector entry point can be built without touching internals.
* Raised the required environment to Dart `>=3.13.0` and Flutter `>=3.47.0`; the example app now
  uses the same constraints.
* Example app: migrated iOS from CocoaPods to Swift Package Manager (Podfile, `Podfile.lock` and
  `Pods/` removed, xcconfigs and workspace cleaned) and adopted the `UIScene` lifecycle
  (`UIApplicationSceneManifest` with `FlutterSceneDelegate`, `AppDelegate` now registers plugins via
  `FlutterImplicitEngineDelegate`).

## 2.6.2

* Fixed `No ScaffoldMessenger widget found` crash when tapping copy buttons (request/response body, headers, error, stack trace, JSON viewer, cURL) inside apps whose widget tree does not expose a `ScaffoldMessenger` above Chuck's screens.
  * Chuck's calls list, call details and stats screens now install their own `ScaffoldMessenger`.
  * All snack bars go through `ChuckSnackBarHelper`, which uses `ScaffoldMessenger.maybeOf` and logs instead of throwing when no messenger is reachable.

## 2.6.1

* Fixed `prefer_if_elements_to_conditional_expressions` lint violations in JSON viewer widget to resolve pub.dev pana static analysis and platform score.

## 2.6.0

* **Performance & Zero Overhead**:
  * Added `enabled` flag (default `true`). When set to `false`, interceptors short-circuit immediately with zero logging, zero memory allocation, and zero overhead for production builds.
  * Added `maxBodySize` parameter (default 1 MB) to prevent OOM crashes on huge payloads (e.g. large file downloads, binary streams).
  * Debounced notifications (350ms) to eliminate platform channel jank on high-frequency API traffic.
  * Notifications automatically suppressed while the inspector UI is open.
  * $O(1)$ memory limit eviction via efficient bounded FIFO buffer.
* **Size Optimization**:
  * Completely removed `permission_handler` and 5 native sub-packages, significantly reducing APK/IPA binary size.
  * Streamlined file export and sharing with `share_plus` (`XFile`) requiring zero Android storage permissions.
  * Optimized `.pubignore` by excluding platform and test build artifacts, reducing pub.dev archive size from 125 KB down to 39 KB (~70% reduction).
* **UI & Theme Overhaul**:
  * Re-architected theme system around Flutter `ThemeExtension` (`ChuckThemeExtension`) with comprehensive light & dark tokens (semantic status colors, HTTP method badges, JSON syntax highlighting).
  * Redesigned calls list screen with a clean search bar, modern call cards, and bottom safe area padding.
  * Modernized call details screen with structured copyable cards, tabbed views, and live reactive stream updates.
  * Completely revamped Stats screen into an informative dashboard with KPI summary cards, timing latency metrics, transfer breakdown, and HTTP methods analytics.
  * Themed interactive JSON tree viewer with full syntax coloring.
* **Bug Fixes**:
  * Fixed bug where Dio and HttpClient response/request headers were lost due to iterating unpopulated maps.
  * Fixed `addError` not clearing `loading = false` or calculating call duration, leaving errored calls indefinitely in pending state.
  * Fixed average duration calculation in Stats screen that was overwriting sums instead of accumulating.
  * Fixed `firstWhere` crash in call details screen when a call was evicted from FIFO while being viewed.
  * Fixed stale state in call details tab views by propagating reactive calls.

## 2.5.0

* Updated dependencies.

## 2.4.3

* Added `ChuckThemeExtension` and `ChuckThemeData` exports for package-level Chuck UI theming.
* Fixed Chuck dialogs and screens to respect host app light/dark theme without forcing light mode.
* Fixed theme token propagation so custom Chuck theme overrides are preserved when attaching to
  `ThemeData`.
* Added `onAccent` theme token to ensure readable foreground content on accent-colored surfaces.
* Updated core Chuck UI widgets to use Chuck theme tokens instead of relying on host text theme
  colors.

## 2.4.2

* Version bump for publishing

## 2.4.1

* update version to 2.4.1 and upgrade flutter_local_notifications to 21.0.0

## 2.4.0

* Updated dependencies: flutter_local_notifications to ^20.0.0

## 2.3.3

* Updated dependencies: share_plus to ^12.0.1, flutter_local_notifications to ^19.5.0
* Migrated from flutter_lints to analysis_lints for better code analysis
* Minor improvements and code quality enhancements
* Version bump for publishing

## 2.3.2

* Version bump for publishing

## 2.3.1

* Version bump for publishing

## 2.3.0

* Performance optimizations and memory management improvements
* Enhanced error handling with comprehensive try-catch blocks
* Improved null safety patterns and defensive programming
* Added comprehensive code documentation and inline comments
* Created unit test suite for core functionality
* Fixed README.md documentation errors and API inconsistencies
* Optimized list operations and reduced memory allocations
* Better user feedback and error recovery mechanisms
* Fixed JSON parsing issues in response preview widgets
* Enhanced JSON detection and validation logic
* Improved error handling for malformed JSON responses
* Better fallback display for JSON parsing failures
* Added detailed error messages for debugging JSON issues
* Fixed Content-Type detection when headers show "unknown"
* Enhanced Content-Type header parsing for different HTTP client formats
* Improved JSON detection logic to work even with unknown content types
* Better fallback to structure-based JSON detection
* Enhanced text response detection for unknown content types
* Improved JSON display with interactive JsonViewer widget
* Added beautiful styling and formatting for JSON responses
* Enhanced JSON readability with expandable/collapsible structure
* Better visual separation and container styling for JSON content
* Fixed JSON parsing to show structured view instead of raw text
* Removed Preview tab from HTTP call details screen
* Simplified UI by removing redundant preview functionality
* Updated tab controller to use 4 tabs instead of 5
* Cleaned up unused preview widget code
* Restored Preview tab to HTTP call details screen
* Simplified ChuckCallResponseWidget to show single view (raw body)
* Enhanced ChuckCallResponsePreviewWidget with interactive JSON viewer
* Separated concerns: Response tab shows raw data, Preview tab shows formatted view
* Improved user experience with dedicated preview functionality
* Updated dependencies

## 2.2.7

* Updated dependencies.

## 2.2.6

* Updated dependencies.

## 2.2.5

* Updated dependencies.

## 2.2.4

* Updated dependencies.

## 2.2.3

* Updated dependencies.

## 2.2.2

* Updated dependencies.

## 2.2.1

* Updated dependencies.

## 2.2.0

* Updated dependencies.

## 2.1.9

* Updated dependencies.

## 2.1.8

* Updated dependencies.

## 2.1.7

* Updated dependencies.

## 2.1.6

* Updated dependencies.

## 2.1.5

* Updated dependencies.

## 2.1.4

* Updated dependencies.

## 2.1.3

* Thank you, @Hayotbek_Ferghana, for fixing the ui bug!

## 2.1.2

* UI bug fixes. Updated dependencies.

## 2.1.1

* Updated dependencies.

## 2.1.0

* Updated dependencies. Updates minimum supported SDK version to Flutter 3.19 /Dart 3.3.0

## 2.0.9

* Updated dependencies

## 2.0.8

* Updated dependencies

## 2.0.7

* Updated dependencies

## 2.0.6+1

* Updated dependencies

## 2.0.5

* flutter_local_notifications package updated

## 2.0.4

* json viewer ui changes

## 2.0.3

* json viewer ui changes

## 2.0.2

* Updates minimum supported SDK version to Flutter 3.13/Dart 3.1.0

## 2.0.0+2

* http bug fixed

## 2.0.0+1

* Updated dependencies

## 2.0.0

* flutter 2.10.0 support, dart 3 support

## 1.1.4

* Updated dependencies

## 1.1.3

* migration Flutter sdk 3.7.0

## 1.1.2

* bug fixed

## 1.1.1

* bug fixed

## 1.1.0

* chopper package removed from dependencies

## 1.0.9

* collection package removed from dependencies

## 1.0.8

* Updated dependencies

## 1.0.7

* open_file package remove

## 1.0.6

* Updated dependencies

## 1.0.5

* Updated dependencies, Bug fixes

## 1.0.4

* Updated dependencies

## 1.0.3

* Updated dependencies

## 1.0.2

* Updated dependencies

## 1.0.1

* Updated dependencies

## 1.0.0

* Updated dependencies

## 0.0.8

* Updated dependencies

## 0.0.7

* Bug fixed

## 0.0.6

* Updated dependencies

## 0.0.5

* Updated dependencies

## 0.0.4

* Updated dependencies

## 0.0.3

* Details page bug fixed

## 0.0.2

* Updated dependencies

## 0.0.1

* Initial release
