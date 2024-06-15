import 'package:flutter/foundation.dart';

abstract interface class UriSchemaHandler {
  bool canHandle(Uri uri);

  Stream<Uint8List> getContentStream(
    Uri uri,
    UriSchemaHandlerParams params,
  );

  Future<bool> canFetchContent(
    Uri uri,
    UriSchemaHandlerParams params,
  );

  Future<int?> getContentLength(
    Uri uri,
    UriSchemaHandlerParams params,
  );
}

class UriSchemaHandlerParams {
  static const defaultBufferSize = 1024 * 1024 * 10;

  final int bufferSize;
  final Map<String, Object> httpHeaders;

  const UriSchemaHandlerParams({
    this.httpHeaders = const {},
    this.bufferSize = defaultBufferSize,
  });
}
