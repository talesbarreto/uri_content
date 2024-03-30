`uri_content` allows you to fetch the content of a URI without creating any temporary files during the process. You don't need to worry about any garbage being left behind.

It supports the following schemes: `file`, `data`, `http/https`, `content` (Android only)

## Getting Started

```dart
import 'package:uri_content/uri_content.dart';
```

### Using `getContent()` function

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

### `UriContent` instance

`UriContent` is preferred because it offers additional options such as custom HTTP headers and the ability to adjust the default buffer size for content schemes. It also facilitates code testing since you can mock its instance.

```dart

final uriContent = UriContent();

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
### Methods

```dart
final uriContent = UriContent();
```

#### getContentStream()

This method retrieves a Stream of Uint8List where each event represents a chunk of content from the specified URI. This approach is more suitable when you don't need the entire content at once, such as in a request provider or when directly saving the bytes into a File. Handling small chunks significantly reduces memory consumption.

```dart
Stream<Uint8List> contentStream = uriContent.getContentStream(uri);
```

#### from()

This method retrieves the entire content at once. Be cautious as it may crash your app when attempting to retrieve a large file.

```dart
Future<Uint8List> content = uriContent.from(uri);
```

#### fromOrNull()

Same as `from`, but returns null instead of throwing an exception when an error happens.

```dart
Future<Uint8List?> content = uriContent.fromOrNull(uri);
```

#### canFetchContent()

This method checks if it is possible to fetch the content from the specified Uri. If it is a file, it checks if it exists. If it is a http/https Uri, it checks if it is reachable.

```dart
Future<bool> canFetch = uriContent.canFetchContent(uri);
```

#### getContentLength()

This method retrieves the content length. Returns null if the length is unknown.

```dart
Future<int?> contentLength = uriContent.getContentLength(uri);
```

#### getContentLengthOrNull()

Same as `getContentLength`, but return `null` on errors. Note that 'null' is ambiguous, it may mean that the content is not reachable or the content length is not available, so it is recommended to use `canFetchContent` to check if the content is reachable.

```dart
Future<int?> contentLength = uriContent.getContentLengthOrNull(uri);
```
