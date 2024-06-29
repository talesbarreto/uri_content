## 2.2.0
* Avoiding excessive memory usage when reading content from `content scheme` by only reading new data chunk when the previous one has been consumed.
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
