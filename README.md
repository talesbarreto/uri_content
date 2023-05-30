## Supported schemes:
- file
- data
- http/https
- content (Android only)

## Getting Started

```dart
import 'package:uri_content/uri_content.dart';
```
### `UriContent` instance

```dart

final uriContent = UriContent();

Future<Uint8List?> getContentFromUri(Uri uri) async {
  try {
    // Attention! To make this try/catch work, you DO need this await 
    return await uriContent.from(uri);
  } catch (e, s) {
    return null;
  }
}

```
### Methods available:
 - `Stream<Uint8List> getContentStream(Uri uri)`: Retrieves a Stream of Uint8List where each event represents a chunk of content from the specified URI. This approach is more suitable when you don't need the entire content at once, such as in a request provider or when directly saving the bytes into a File. Handling small chunks significantly reduces memory consumption.
 - `Future<Uint8List> from(Uri uri)`: Retrieves the entire content at once. Be cautious as it may crash your app when attempting to retrieve a large file.
 - `Future<Uint8List?> fromOrNull(Uri uri)`: Same as `from`, but returns null instead of throwing an exception when an error happens

### Extension function

```dart
Future<Uint8List?> getContentFromUri(Uri uri) async {
  try {
    return await uri.getContent();
  } catch (e, s) {
    return null;
  }
}
```
The function `getContentOrNull()` is also available if you are not interested in handling errors.
