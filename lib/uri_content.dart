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
  Future<Uint8List> getContent() => UriContent().from(this);

  /// same as [getContent] but return `null` on errors.
  Future<Uint8List?> getContentOrNull() => UriContent().fromOrNull(this);
}

class UriContent {
  final UriContentNativeApi _uriContentNativeApi;
  final HttpClient _httpClient;
  final UriSerializer _uriSerializer;

  static String _defaultUriSerializer(Uri uri) => uri.toString();

  /// [uriSerializer] is used to serialize tha URI to send it to the Android Platform when its scheme is `content`.
  /// On Android side, the URI will be parsed again.
  UriContent({
    UriContentNativeApi? uriContentNativeApi,
    HttpClient? httpClient,
    UriSerializer uriSerializer = _defaultUriSerializer,
  })  : _uriSerializer = uriSerializer,
        _uriContentNativeApi = uriContentNativeApi ?? UriContentNativeApi(),
        _httpClient = httpClient ?? HttpClient();

  /// same as [from] but return `null` on errors.
  Future<Uint8List?> fromOrNull(Uri uri) async {
    try {
      return await from(uri);
    } catch (e) {
      return null;
    }
  }

  /// Get the content from an Uri.
  /// Supported schemes: data, file, http, https, Android content
  ///
  /// Throws exception if it was nos possible to get the content
  Future<Uint8List> from(Uri uri) async {
    if (uri.scheme == UriScheme.data) {
      final data = uri.data;
      if (data != null) {
        return data.contentAsBytes();
      } else {
        return Future.error(
          Exception(
            "The URI has a data scheme, but its data is null.",
          ),
        );
      }
    }

    if (uri.scheme == UriScheme.file) {
      final file = File.fromUri(uri);
      final content = await file.readAsBytes();
      return Uint8List.fromList(content);
    }

    if (uri.scheme == UriScheme.http || uri.scheme == UriScheme.https) {
      final request = await _httpClient.getUrl(uri);
      final response = await request.close();
      return response.fold<Uint8List>(Uint8List(0), (previous, element) {
        return Uint8List.fromList([...previous, ...element]);
      });
    }

    if (Platform.isAndroid && uri.scheme == UriScheme.content) {
      return _uriContentNativeApi.getContentFromUri(_uriSerializer(uri));
    }

    try {
      // unsupported scheme, trying to get its content anyway
      return uri.data!.contentAsBytes();
    } catch (e) {
      if (!Platform.isAndroid && uri.scheme == UriScheme.content) {
        return Future.error(
          "`content` scheme is only supported on Android.",
        );
      }
      return Future.error(
        "scheme `${uri.scheme}` is not supported. "
        "Feel free to open an issue or submit an pull request at https://github.com/talesbarreto/uri_content",
      );
    }
  }
}
