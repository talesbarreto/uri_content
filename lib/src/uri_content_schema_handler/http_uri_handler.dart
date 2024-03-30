import 'dart:io';
import 'dart:typed_data';

import 'package:uri_content/src/uri_content_schema_handler/uri_schema_handler.dart';

class HttpUriHandler implements UriSchemaHandler {
  final HttpClient httpClient;

  final Map<String, Object> defaultHttpHeaders;

  const HttpUriHandler({
    required this.httpClient,
    required this.defaultHttpHeaders,
  });

  @override
  bool canHandle(Uri uri) {
    return uri.scheme == "http" || uri.scheme == "https";
  }

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

  @override
  Future<bool> canFetchContent(
    Uri uri,
    UriSchemaHandlerParams params,
  ) async {
    try {
      final request = await httpClient.headUrl(uri);
      _addHeadersToRequest(request, params.httpHeaders);
      final response = await request.close();
      return response.statusCode == HttpStatus.ok;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<int?> getContentLength(
    Uri uri,
    UriSchemaHandlerParams params,
  ) async {
    final request = await httpClient.headUrl(uri);
    _addHeadersToRequest(request, params.httpHeaders);
    final response = await request.close();
    final length = response.headers['content-length']?.firstOrNull ?? '';
    return int.tryParse(length);
  }

  @override
  Stream<Uint8List> getContentStream(
    Uri uri,
    UriSchemaHandlerParams params,
  ) async* {
    try {
      final request = await httpClient.getUrl(uri);
      _addHeadersToRequest(request, params.httpHeaders);
      final response = await request.close();
      yield* response.map(Uint8List.fromList);
    } catch (e, s) {
      yield* Stream.error(e, s);
    }
  }
}
