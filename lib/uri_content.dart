import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uri_content/src/native_api/uri_content_native_api.dart';
import 'package:uri_content/src/uri_scheme.dart';

typedef UriSerializer = String Function(Uri uri);

extension UriContentGetter on Uri {
  /// [getContent] extension makes the process of get the content from an Uri easier.
  /// If you don't mind about clean architecture or code testability, use it directly.
  /// Otherwise, you can use [UriContent] to make it injectable and possible to mock
  ///
  /// Throws exception if it was nos possible to get the content
  Future<Uint8List> getContent() => UriContent._instance.from(this);

  /// same as [getContent] but return `null` on errors.
  Future<Uint8List?> getContentOrNull() => UriContent._instance.fromOrNull(this);
}

class UriContent implements UriContentFlutterApi {
  /// Be careful using [UriContent.internal] constructor. You may leak resources in
  /// [_pendingContentRequests] and mess with the native callback set in [_init]
  /// If you do need to replace any dependency, do it before get any content and
  /// use [setInstance] to replace the singleton instance.
  UriContent.internal({
    UriContentNativeApi? uriContentNativeApi,
    HttpClient? httpClient,
    UriSerializer uriSerializer = _defaultUriSerializer,
  })  : _uriSerializer = uriSerializer,
        _uriContentNativeApi = uriContentNativeApi ?? UriContentNativeApi(),
        _httpClient = httpClient ?? HttpClient();

  // Sorry kids, it is necessary to listen to Native calls and store
  // pending requests in `_pendingContentRequests`. It would be a mess if
  // we had several instances of UriContent.
  static UriContent _instance = UriContent.internal().._init();

  factory UriContent() => UriContent._instance;

  final UriContentNativeApi _uriContentNativeApi;
  final HttpClient _httpClient;
  final UriSerializer _uriSerializer;

  // Used on `android content` scheme.
  final _pendingContentRequests = <int, StreamController<Uint8List>>{};

  static String _defaultUriSerializer(Uri uri) => uri.toString();

  static void setInstance(UriContent uriContent) {
    final oldInstance = UriContent._instance;
    UriContent._instance = uriContent;
    uriContent._init();
    oldInstance._dispose();
  }

  void _init() {
    UriContentFlutterApi.setup(this);
  }

  /// [_dispose] is only called on [setInstance].
  /// There is no need to dispose [UriContent] since it is a singleton
  void _dispose() {
    for (final key in _pendingContentRequests.keys) {
      _pendingContentRequests.remove(key)?.close();
    }
  }

  int _requestId = 0;

  /// same as [getContentStream] but return `null` on errors.
  Future<Uint8List?> fromOrNull(Uri uri) async {
    try {
      return from(uri);
    } catch (e) {
      return null;
    }
  }

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

  Stream<Uint8List> _fromAndroidContentUri(Uri uri, int bufferSize) {
    final requestId = _requestId++;
    final controller = StreamController<Uint8List>();
    _pendingContentRequests[requestId] = controller;
    controller.onListen = () {
      _uriContentNativeApi.getContentFromUri(
        _uriSerializer(uri),
        requestId,
        bufferSize,
      );
    };
    return controller.stream;
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

  void _removeRequest(int requestId) {
    _pendingContentRequests.remove(requestId)?.close();
  }

  @override
  void onDataReceived(int requestId, Uint8List? data, String? error) {
    final controller = _pendingContentRequests[requestId];
    if (controller != null) {
      if (controller.isClosed) {
        _pendingContentRequests.remove(requestId);
      }
      if (error != null) {
        controller.addError(error);
        _removeRequest(requestId);
      } else {
        if (data == null) {
          _removeRequest(requestId);
        } else {
          controller.add(data);
        }
      }
    }
  }
}
