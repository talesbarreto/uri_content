import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uri_content/src/internal_platform.dart';
import 'package:uri_content/src/native_data_provider/uri_content_flutter_api_impl.dart';
import 'package:uri_content/src/uri_content_exception.dart';
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
  final UriContentApi _uriContentApi;
  final InternalPlatform _platform;

  /// [defaultHttpHeaders] see https://api.flutter.dev/flutter/dart-io/HttpHeaders/add.html
  final Map<String, Object> defaultHttpHeaders;

  static String _defaultUriSerializer(Uri uri) => uri.toString();

  UriContent({
    this.defaultHttpHeaders = const {},
    HttpClient? httpClient,
    UriSerializer uriSerializer = _defaultUriSerializer,
    UriContentApi? uriContentApi,
    InternalPlatform? internalPlatform,
  })  : _uriSerializer = uriSerializer,
        _httpClient = httpClient ?? HttpClient(),
        _uriContentApi = uriContentApi ?? UriContentApi(),
        _platform = internalPlatform ?? InternalPlatform();

  final HttpClient _httpClient;
  final UriSerializer _uriSerializer;

  void _addHeadersToRequest(
    HttpClientRequest request,
    Map<String, Object> headers,
  ) {
    for (final header in defaultHttpHeaders.entries) {
      request.headers.set(header.key, header.value);
    }
    for (final header in headers.entries) {
      request.headers.set(header.key, header.value);
    }
  }

  Stream<Uint8List> _fromHttpUri(
    Uri uri,
    Map<String, Object> httpHeaders,
  ) async* {
    final request = await _httpClient.getUrl(uri);
    _addHeadersToRequest(request, httpHeaders);
    final response = await request.close();
    yield* response.map(Uint8List.fromList);
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
      yield* Stream.error(UriContentError.dataSchemeWithNoData);
    }
  }

  Stream<Uint8List> _fromAndroidContentUri(Uri uri, int bufferSize) async* {
    final requestId = _uriContentApi.getNextId();

    Stream<Uint8List> currentRequestBytesStream() async* {
      await for (final data in _uriContentApi.newDataReceivedStream) {
        if (data.requestId == requestId) {
          final error = data.error;
          final bytes = data.data;
          if (error != null) {
            yield* Stream.error(UriContentError(error));
            break;
          }
          if (bytes != null) {
            yield bytes;
          } else {
            break; // EOF
          }
        }
      }
    }

    final controller = StreamController<Uint8List>(
      onListen: () {
        _uriContentApi.getContentFromUri(_uriSerializer(uri), requestId, bufferSize);
      },
      onCancel: () {
        _uriContentApi.onRequestCancelled(requestId);
      },
    );

    controller.addStream(currentRequestBytesStream()).then((_) {
      controller.close();
    });

    yield* controller.stream;
  }

  Stream<Uint8List> _fromUnknownUri(Uri uri) async* {
    try {
      // unsupported scheme, trying to get its content anyway
      yield uri.data!.contentAsBytes();
    } catch (e) {
      if (!_platform.isAndroid && uri.scheme == UriScheme.content) {
        yield* Stream.error(UriContentError.contentOnlySupportedByAndroid);
      }
      yield* Stream.error(UnsupportedSchemeError(uri.scheme));
    }
  }

  /// Get the content from an Uri.
  /// Supported schemes: data, file, http, https, Android content
  ///
  ///
  /// [httpHeaders] see https://api.flutter.dev/flutter/dart-io/HttpHeaders/add.html
  ///
  /// Throws exception if it was nos possible to get the content
  ///
  /// Consider using [getContentStream] if you are retrieving a large file
  Future<Uint8List> from(
    Uri uri, {
    Map<String, Object> httpHeaders = const {},
  }) async {
    return getContentStream(uri, httpHeaders: httpHeaders).fold(
      Uint8List(0),
      (previous, element) => Uint8List.fromList([...previous, ...element]),
    );
  }

  /// same as [getContentStream] but return `null` on errors.
  Future<Uint8List?> fromOrNull(
    Uri uri, {
    Map<String, Object> httpHeaders = const {},
  }) async {
    try {
      final result = await from(uri, httpHeaders: httpHeaders);
      return result;
    } catch (e) {
      return null;
    }
  }

  /// [getContentStream] returns a Stream of Uint8List where each event represents a chunk of the content from the specified URI.
  /// This approach is more suitable when you don't need the entire content at once, such as in a request provider or
  /// when directly saving the bytes into a File.
  /// Handling small chunks significantly reduces memory consumption.
  ///
  /// [httpHeaders] see https://api.flutter.dev/flutter/dart-io/HttpHeaders/add.html
  ///
  /// [bufferSize] sets the total of bytes to be send on each stream event. It ONLY affects `android content` Uris
  ///
  /// Warning: To prevent resource leaks, make sure to either listen to the stream until the end or close it
  /// if you want to abort the content reading.
  Stream<Uint8List> getContentStream(
    Uri uri, {
    int bufferSize = 1024 * 512,
    Map<String, Object> httpHeaders = const {},
  }) {
    if (uri.scheme == UriScheme.data) {
      return _fromDataUri(uri);
    }

    if (uri.scheme == UriScheme.file) {
      return _fromFileUri(uri);
    }

    if (uri.scheme == UriScheme.http || uri.scheme == UriScheme.https) {
      return _fromHttpUri(uri, httpHeaders);
    }

    if (_platform.isAndroid && uri.scheme == UriScheme.content) {
      return _fromAndroidContentUri(uri, bufferSize);
    }

    return _fromUnknownUri(uri);
  }

  Future<bool> doesContentExist(Uri uri) {
    if (uri.scheme == UriScheme.data) {
      return SynchronousFuture(uri.data != null);
    }

    if (uri.scheme == UriScheme.file) {
      return File.fromUri(uri).exists();
    }

    if (uri.scheme == UriScheme.http || uri.scheme == UriScheme.https) {
      return _httpClient.headUrl(uri).then((request) async {
        final response = await request.close();
        return response.statusCode == HttpStatus.ok;
      });
    }

    if (uri.scheme == UriScheme.content) {
      if (_platform.isAndroid) {
        return _uriContentApi.doesFileExist(_uriSerializer(uri));
      } else {
        return SynchronousFuture(false);
      }
    }

    return SynchronousFuture(false);
  }
}
