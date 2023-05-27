import 'dart:io';
import 'dart:typed_data';
import 'package:uri_content/src/native_api/uri_content_native_api.dart';

extension UriContentGetter on Uri {
  /// [getContent] extension makes the process of get the content from an Uri easier.
  /// If you don't mind about clean architecture or code testability, use it directly.
  /// Otherwise, you can use [UriContent] to make it injectable and possible to mock
  Future<Uint8List> getContent() => UriContent().from(this);
}

class UriContent {
  final UriContentNativeApi _uriContentNativeApi;
  final HttpClient _httpClient;
  final String Function(Uri uri) uriSerializer;

  static String _defaultUriSerializer(Uri uri) => uri.toString();

  UriContent({
    UriContentNativeApi? uriContentNativeApi,
    HttpClient? httpClient,
    this.uriSerializer = _defaultUriSerializer,
  })  : _uriContentNativeApi = uriContentNativeApi ?? UriContentNativeApi(),
        _httpClient = httpClient ?? HttpClient();

  /// Get the content from an Uri.
  /// Supported schemes: data, file, http, https, Android content
  Future<Uint8List> from(Uri uri) async {
    if (uri.scheme == "data") {
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

    if (uri.scheme == "file") {
      final file = File.fromUri(uri);
      final content = await file.readAsBytes();
      return Uint8List.fromList(content);
    }

    if (uri.scheme == "http" || uri.scheme == "https") {
      final request = await _httpClient.getUrl(uri);
      final response = await request.close();
      return response.fold<Uint8List>(Uint8List(0), (previous, element) {
        return Uint8List.fromList([...previous, ...element]);
      });
    }
    if (Platform.isAndroid && uri.scheme == "content") {
      return _uriContentNativeApi.getContentFromUri(uriSerializer(uri));
    }

    return Future.error(
      "Could not get content from `$uri` scheme `${uri.scheme}`",
    );
  }
}
