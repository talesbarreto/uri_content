## 3.1.0+1

* Documentation updates

* ## 3.1.0
* Updates minimum supported SDK version to Dart 3.0
* Fix `OutOfMemoryError` crash
* Memory usage optimization on `content` scheme reading

## 3.0.0

### Updated the project to use the Flutter 3.29.0 structure

- **Android min SDK Version**:
    - Updated minimum SDK version from `16` to `21` (older devices with SDK version < 21.0 are no
      longer supported)
- **iOS Deployment Target**:
    - Updated minimum iOS version from `11.0` to `12.0` (older devices with iOS < 12.0 are no longer
      supported)
- **Kotlin Version**:
    - Updated from `1.7.10` to `1.8.22` (may require code changes to support new version)
- **Gradle Version**:
    - Updated from `7.4` to `8.9` (may require changes in build scripts)
- **Gradle Properties**:
    - Updated JVM args and other properties
- **Android Gradle Plugin**:
    - Updated from `7.2.0` to `8.7.0` (may require changes in build configuration)

## 2.2.1

- Android's Gradle script adapted to support new AGP versions

## 2.2.0

* Avoiding excessive memory usage when reading content from `content scheme` by only reading new
  data chunk when the previous one has been consumed.
* Min SDK version is now 2.17.0

## 2.1.1

* Fixing docs

## 2.1.0

* New`getContentLength` function

## 2.0.0

* Adding `org.jetbrains.kotlinx:kotlinx-coroutines-android` Android dependency
* New `canFetchContent` function
* Reading `content scheme` is now done in a separate thread, avoiding ANRs.
* Aborting `content scheme` reading when stream is no longer being listened to.
* Error handling improvements

## 1.1.0

* Support for custom http headers

## 1.0.0

* Stable version

## 0.0.6

* Improved error handling

## 0.0.5

* Fix false `Unclosed instance of 'Sink'.` warning by pub dev

## 0.0.4

* new `getContentStream` method, allowing to retrieve chunks of buffered data instead of the entire
  data at once.

## 0.0.3

* support for linux, macos and windows
* Removed `pigeon` dependency

## 0.0.2

* new `getContentOrNull` getter and `fromOrNull` function

## 0.0.1

* Experimental version
