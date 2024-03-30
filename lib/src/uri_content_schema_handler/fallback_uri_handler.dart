import 'package:flutter/foundation.dart';
import 'package:uri_content/src/uri_content_schema_handler/uri_schema_handler.dart';

import '../model/uri_content_exception.dart';

class FallbackUriHandler implements UriSchemaHandler {
  const FallbackUriHandler();

  @override
  bool canHandle(Uri uri) {
    return false;
  }

  @override
  Future<bool> canFetchContent(
    Uri uri,
    UriSchemaHandlerParams _,
  ) {
    return SynchronousFuture(uri.data != null);
  }

  @override
  Stream<Uint8List> getContentStream(
    Uri uri,
    UriSchemaHandlerParams _,
  ) async* {
    try {
      yield uri.data!.contentAsBytes();
    } catch (e) {
      yield* Stream.error(UnsupportedSchemeError(uri.scheme));
    }
  }

  @override
  Future<int?> getContentLength(Uri uri, UriSchemaHandlerParams params) {
    return SynchronousFuture(uri.data?.contentAsBytes().length);
  }
}
