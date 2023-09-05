`uri_content` allows you to fetch the content of a URI without creating any temporary files during the process. You don't need to worry about any garbage being left behind.


## Supported schemes:
- file
- data
- http/https
- content (Android only)

## Getting Started

```dart
import 'package:uri_content/uri_content.dart';
```

### Extension function

```dart
Future<void> printPullRequestCoverageReadme() async {
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

```dart

final uriContent = UriContent();

Future<void> printPullRequestCoverageReadmeLength() async {
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
### Methods available:
 - `Stream<Uint8List> getContentStream(Uri uri)`: Retrieves a Stream of Uint8List where each event represents a chunk of content from the specified URI. This approach is more suitable when you don't need the entire content at once, such as in a request provider or when directly saving the bytes into a File. Handling small chunks significantly reduces memory consumption.
 - `Future<Uint8List> from(Uri uri)`: Retrieves the entire content at once. Be cautious as it may crash your app when attempting to retrieve a large file.
 - `Future<Uint8List?> fromOrNull(Uri uri)`: Same as `from`, but returns null instead of throwing an exception when an error happens


The function `getContentOrNull()` is also available if you are not interested in handling errors.
