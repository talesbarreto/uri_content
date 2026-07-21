[![PubStats Popularity](https://pubstats.dev/badges/packages/uri_content/popularity.svg)](https://pubstats.dev/packages/uri_content) [![PubStats Rank](https://pubstats.dev/badges/packages/uri_content/rank.svg)](https://pubstats.dev/packages/uri_content)

# uri_content

Get `Uint8List` content from a `Uri` in Flutter.

This package reads content directly from the original source and streams bytes in memory. **It does not create temporary files** while fetching content.

## Supported URI schemes

- `data:`
- `file:`
- `http:`
- `https:`
- `content:` (Android only)

## Usage styles

You can use `uri_content` in two ways:

1. `Uri` extension methods (`getContent()` / `getContentOrNull()`).
2. A `UriContent` instance (recommended for testability, injection, custom headers, and Android `content:` buffer tuning).

## Quick start

```dart
import 'dart:typed_data';
import 'package:uri_content/uri_content.dart';

Future<Uint8List> loadBytes() async {
  final uri = Uri.parse('https://example.com/file.bin');
  try {
    return await uri.getContent(); // extension on Uri
  } catch (e) {
    // getContent() can throw when content can't be retrieved.
    rethrow;
  }
}
```

If you prefer nullable behavior on failure:

```dart
final bytesOrNull = await Uri.parse('https://example.com/file.bin').getContentOrNull();
```

## Using `UriContent` directly

Use `UriContent` when you want dependency injection/mocking, custom headers, a custom `HttpClient`, or control over Android `content:` read buffer size.

```dart
import 'dart:io';
import 'package:uri_content/uri_content.dart';

final uriContent = UriContent(
  defaultHttpHeaders: {'Authorization': 'Bearer <token>'},
  httpClient: HttpClient(),
);

final bytes = await uriContent.from(
  Uri.parse('https://example.com/private.bin'),
  httpHeaders: {'X-Request-Id': 'abc-123'},
);
```

## Streaming large content

`from()` returns all bytes in a single `Uint8List`. For large files, prefer `getContentStream()` to process chunks and reduce memory usage. Fetching very large content with `from()` may use too much memory and can crash your app.

```dart
import 'package:uri_content/uri_content.dart';

final uri = Uri.parse('https://example.com/large-file.zip');
final stream = UriContent().getContentStream(uri);

await for (final chunk in stream) {
  // process/save chunk
}
```

If you stop early, cancel the stream subscription. Always consume the stream to completion or cancel it to avoid resource leaks.

For Android `content:` URIs, `bufferSize` controls chunk size (default: 5 MB). Larger values can considerably increase performance, while smaller values reduce memory consumption:

```dart
final stream = UriContent().getContentStream(
  Uri.parse('content://...'),
  bufferSize: 1024 * 1024, // 1 MB
);
```

## Utility methods

```dart
final uriContent = UriContent();
final uri = Uri.parse('https://example.com/file.bin');

final canFetch = await uriContent.canFetchContent(uri);
final length = await uriContent.getContentLength(uri); // may be null
final lengthOrNull = await uriContent.getContentLengthOrNull(uri);
```

- `canFetchContent()` checks whether content can be fetched (for example, file existence for `file:` URIs and reachability for `http/https` URIs).
- `getContentLength()` uses metadata and may be inaccurate; it can throw if content is not reachable; it returns `null` when length is unavailable.
- `getContentLengthOrNull()` returns `null` on errors, but `null` is ambiguous (unreachable content vs unavailable length).

## Errors

- `from()` and `getContent()` throw when content cannot be retrieved.
- `fromOrNull()` and `getContentOrNull()` return `null` on errors.
- Unsupported schemes throw `UnsupportedSchemeError`.
