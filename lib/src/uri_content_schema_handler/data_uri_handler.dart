import 'package:flutter/foundation.dart';
import 'package:uri_content/src/uri_content_schema_handler/uri_schema_handler.dart';

import '../model/uri_content_exception.dart';

class DataUriHandler implements UriSchemaHandler {
  const DataUriHandler();

  @override
  bool canHandle(Uri uri) {
    return uri.scheme == "data";
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
    final data = uri.data;
    if (data != null) {
      yield data.contentAsBytes();
    } else {
      yield* Stream.error(UriContentError.dataSchemeWithNoData);
    }
  }

  @override
  Future<int?> getContentLength(Uri uri, UriSchemaHandlerParams params) {
    final data = uri.data;
    return SynchronousFuture(data?.contentAsBytes().length);
  }
}
