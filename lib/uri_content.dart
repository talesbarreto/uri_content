import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uri_content/src/native_api/uri_content_native_api.dart';
import 'package:uri_content/src/native_data_provider/native_data_provider.dart';
import 'package:uri_content/src/uri_scheme.dart';

typedef UriSerializer = String Function(Uri uri);

extension UriContentGetter on Uri {
  /// The [getContent] extension simplifies the process of retrieving content from a Uri.
  /// If you don't mind disregarding clean architecture or code testability, you can use it directly.
  /// However, if you prefer a more flexible approach, you can utilize [UriContent] to make it injectable and mockable.
  ///
  /// Note that [getContent] will throw an exception if it is not possible to retrieve the content.
  Future<Uint8List> getContent() => UriContent().from(this);

  /// same as [getContent] but return `null` on errors.
  Future<Uint8List?> getContentOrNull() => UriContent().fromOrNull(this);
}

class UriContent {
  final _nativeApi = NativeDataProvider();

  UriContent({
    UriContentNativeApi? uriContentNativeApi,
    HttpClient? httpClient,
    UriSerializer uriSerializer = _defaultUriSerializer,
  })  : _uriSerializer = uriSerializer,
        _uriContentNativeApi = uriContentNativeApi ?? UriContentNativeApi(),
        _httpClient = httpClient ?? HttpClient();

  final UriContentNativeApi _uriContentNativeApi;
  final HttpClient _httpClient;
  final UriSerializer _uriSerializer;

  static String _defaultUriSerializer(Uri uri) => uri.toString();

  int _androidContentRequestId = 0;

  Stream<Uint8List> _fromHttpUri(Uri uri) async* {
    final request = await _httpClient.getUrl(uri);
    final response = await request.close();
    await for (final chunk in response) {
      yield Uint8List.fromList(chunk);
    }
  }

  Stream<Uint8List> _fromFileUri(Uri uri) {
    final file = File.fromUri(uri);
    return file.openRead().map(Uint8List.fromList);
  }

  Stream<Uint8List> _fromDataUri(Uri uri) async* {
    final data = uri.data;
    if (data != null) {
      yield data.contentAsBytes();
    } else {
      throw Future.error(
        Exception(
          "The URI has a data scheme, but its data is null.",
        ),
      );
    }
  }

  Stream<Uint8List> _fromAndroidContentUri(Uri uri, int bufferSize) async* {
    final requestId = _androidContentRequestId++;
    _uriContentNativeApi.getContentFromUri(
      _uriSerializer(uri),
      requestId,
      bufferSize,
    );
    await for (final data in _nativeApi.stream) {
      if (data.requestId == requestId) {
        final error = data.error;
        final uint8List = data.data;
        if (error != null) {
          throw error;
        }
        if (uint8List != null) {
          yield uint8List;
        } else {
          break; // EOF
        }
      }
    }
  }

  Stream<Uint8List> _fromUnknownUri(Uri uri) async* {
    try {
      // unsupported scheme, trying to get its content anyway
      yield uri.data!.contentAsBytes();
    } catch (e) {
      if (!Platform.isAndroid && uri.scheme == UriScheme.content) {
        throw Future.error(
          "`content` scheme is only supported on Android.",
        );
      }
      throw Future.error(
        "scheme `${uri.scheme}` is not supported. "
        "Feel free to open an issue or submit an pull request at https://github.com/talesbarreto/uri_content",
      );
    }
  }

  /// Get the content from an Uri.
  /// Supported schemes: data, file, http, https, Android content
  ///
  /// Throws exception if it was nos possible to get the content
  ///
  /// Consider using [getContentStream] if you are retrieving a large file
  Future<Uint8List> from(Uri uri) async {
    return getContentStream(uri).fold(Uint8List(0), (previous, element) {
      return Uint8List.fromList([...previous, ...element]);
    });
  }

  /// [getContentStream] returns a Stream of Uint8List where each event represents a chunk of the content from the specified URI.
  /// This approach is more suitable when you don't need the entire content at once, such as in a request provider or
  /// when directly saving the bytes into a File.
  /// Handling small chunks significantly reduces memory consumption.
  ///
  /// [bufferSize] sets the total of bytes to be send on each stream event. It ONLY affects `android content` Uris
  ///
  /// Warning: To prevent resource leaks, make sure to either listen to the stream until the end or close it
  /// if you want to abort the content reading.
  Stream<Uint8List> getContentStream(
    Uri uri, {
    int bufferSize = 1024 * 512,
  }) {
    if (uri.scheme == UriScheme.data) {
      return _fromDataUri(uri);
    }

    if (uri.scheme == UriScheme.file) {
      return _fromFileUri(uri);
    }

    if (uri.scheme == UriScheme.http || uri.scheme == UriScheme.https) {
      return _fromHttpUri(uri);
    }

    if (Platform.isAndroid && uri.scheme == UriScheme.content) {
      return _fromAndroidContentUri(uri, bufferSize);
    }

    return _fromUnknownUri(uri);
  }

  /// same as [getContentStream] but return `null` on errors.
  Future<Uint8List?> fromOrNull(Uri uri) async {
    try {
      return from(uri);
    } catch (e) {
      return null;
    }
  }
}
