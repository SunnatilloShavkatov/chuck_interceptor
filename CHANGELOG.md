## 2.3.0

* The cache box is now bounded. Previously every response and every error was appended to the box
  and nothing was ever removed, so the box grew without limit across app launches and slowed the
  host app down over time.
* Added a cache size picker to the inspector menu. Pick between off, 100, 200, 300 and 1000 calls.
  The choice is stored in the cache box itself and is applied on the next launch.
* Caching is off by default. An existing cache is emptied on startup until a size is picked, so
  upgrading does not leave an oversized box behind.
* A call is now stored under a key derived from its creation time instead of being appended, so
  writing the response and then the error of the same call no longer produces duplicate entries.
* Cached calls are decoded once and reused while unchanged. A box write used to force every
  listening screen to decode the whole box again.
* Fixed a crash when opening a cached call that is no longer in the box.
* Failed cache writes are logged instead of surfacing as unhandled errors in the host app, which
  could happen when the box was closed while a write was still in flight.
* `Chuck` takes a new `maxCacheCount` argument for the initial cache size. It defaults to 0.
* Raised the minimum SDK to Dart 3.11 and Flutter 3.41. Updated dependencies.

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

## 2.0.0+1

* Updated dependencies

## 2.0.0+1

* http bug fixed

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
