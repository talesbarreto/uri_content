Get the content of a Uri

## Supported schemes:

- file
- data
- http/https
- content (Android only)

## Getting Started

```dart
import 'package:uri_content/uri_content.dart';
```

There are two ways to use the `uri_content` plugin

### Extension getter

```dart
Future<Uint8List?> getContentFromUri(Uri uri) async {
  try {
    // Attention! if you don't use `await` here, the exception will 
    // be throw on the `getContentFromUri` and this try/catch will be useless
    return await uri.getContent();
  } catch (e, s) {
    return null;
  }
}
```

### `UriContent` class

A more advanced approach that allows injecting this plugin as a dependency and testing your code.

```dart

final uriContent = UriContent();

Future<Uint8List?> getContentFromUri(Uri uri) async {
  try {
    // Attention! if you don't use `await` here, the exception will 
    // be throw on the `getContentFromUri` and this try/catch will be useless
    return await uriContent.from(uri);
  } catch (e, s) {
    return null;
  }
}


```

____
Warning: This is an experimental version. I developed this package quickly because I needed it for another project.
I still need to write tests and cover all cases. If you find any bugs, feel free to open an issue or submit a Pull Request.