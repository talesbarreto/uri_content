`uri_content` enables you to fetch the content of a URI without generating any temporary files during the process. 
You need not worry about any residual garbage being left behind.

It supports the following schemes: `file`, `data`, `http/https`, `content` (Android only)

## Getting Started

```dart
import 'package:uri_content/uri_content.dart';

final uriContent = UriContent();
```

`UriContent` is preferred because it offers additional options such as custom HTTP headers and the ability to adjust the default buffer size for content schemes. It also facilitates code testing since you can mock its instance.


```dart
Future<void> getReadmeLength() async {
  try {
    final content = await uriContent.from(Uri.parse(
      "https://raw.githubusercontent.com/talesbarreto/pull_request_coverage/main/README.md",
    ));
    print("Content length is ${content.length}");
  } catch (e, s) {
    print("An error happened $e\n$s");
  }
}
```

### getContentStream()

This method retrieves a Stream of Uint8List where each event represents a chunk of content from the specified URI. This approach is more suitable when you don't need the entire content at once, such as in a request provider or when directly saving the bytes into a File. Handling small chunks significantly reduces memory consumption.

```dart
Stream<Uint8List> contentStream = uriContent.getContentStream(uri);
```

### from()

This method retrieves the entire content at once. Be cautious as it may crash your app when attempting to retrieve a large file.
- Throws exception if it was nos possible to get the content

```dart
Future<Uint8List> content = uriContent.from(uri);
```

### fromOrNull()

Similar to `from`, but returns null instead of throwing an exception when an error happens.

```dart
Future<Uint8List?> content = uriContent.fromOrNull(uri);
```

### canFetchContent()

This method checks if it is possible to fetch the content from the specified Uri. If it is a file, it checks if it exists. If it is a http/https Uri, it checks if it is reachable.

```dart
Future<bool> canFetch = uriContent.canFetchContent(uri);
```

### getContentLength()
returns the content length in bytes of the specified Uri.
 - It relies on metadata to get the content length, so it may **not** be accurate.
 - It may throw an exception if the content is not reachable.
 - If the content length is not available, it returns `null`.

```dart
Future<int?> contentLength = uriContent.getContentLength(uri);
```

### getContentLengthOrNull()

Similar to `getContentLength`, but return `null` on errors. 

Note that `null` is ambiguous; it may indicate that the content is not reachable or the content length is unavailable. Hence, it is recommended to use `getContentLength() and handle its exceptions.

```dart
Future<int?> contentLength = uriContent.getContentLengthOrNull(uri);
```

## Using `getContent()` extension

A handy extension method for `Uri` allows direct fetching of URI content.

```dart
Future<void> getReadmeContent() async {
  try {
    final uri = Uri.parse(
      "https://raw.githubusercontent.com/talesbarreto/pull_request_coverage/main/README.md",
    );
    print(await (uri.getContent().then(utf8.decode)));
  } catch (e, s) {
    print("An error happened $e\n$s");
  }
}

```

- `getContentOrNull()` is also available, returning `null` instead of throwing an exception when an error happens.

