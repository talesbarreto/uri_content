import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uri_content/src/platform_api/uri_content_flutter_api_impl.dart';
import 'package:uri_content/src/platform_api/uri_content_native_api.dart';
import 'package:uri_content/src/uri_content_schema_handler/uri_schema_handler.dart';

import '../../uri_content.dart';

class AndroidContentUriHandler implements UriSchemaHandler {
  final UriContentApi uriContentApi;
  final TargetPlatform targetPlatform;
  final UriSerializer uriSerializer;

  const AndroidContentUriHandler({
    required this.uriContentApi,
    required this.targetPlatform,
    required this.uriSerializer,
  });

  @override
  Future<bool> canFetchContent(Uri uri, UriSchemaHandlerParams params) {
    if (targetPlatform == TargetPlatform.android) {
      return uriContentApi.exists(uriSerializer(uri));
    } else {
      return SynchronousFuture(false);
    }
  }

  @override
  bool canHandle(Uri uri) {
    return uri.scheme == "content" && targetPlatform == TargetPlatform.android;
  }

  Stream<Uint8List> _nativeDataStream(
    String uri,
    int requestId,
    int bufferSize,
  ) async* {
    await uriContentApi.startRequest(uri, requestId, bufferSize);

    while (true) {
      final UriContentChunkResult result;
      try {
        // Ideally, we should continuously send data from Kotlin to Dart and Dart should inform the native code when the stream should be paused.
        // However, we can not directly send data from Kotlin to Dart directly if we need to work with multiple isolates, like pointed out in this issue https://github.com/talesbarreto/uri_content/issues/10
        // To overcome this, we request each chunk of data as an ordinary method channel request.
        result = await uriContentApi.requestNextChunk(requestId);
      } catch (e) {
        yield* Stream.error(UriContentError(e.toString()));
        return;
      }
      if (result.error != null) {
        yield* Stream.error(UriContentError(result.error!));
        break;
      } else if (result.done) {
        break;
      } else if (result.chunk != null) {
        yield result.chunk!;
      }
    }
  }

  @override
  Stream<Uint8List> getContentStream(
    Uri uri,
    UriSchemaHandlerParams params,
  ) async* {
    final requestId = uriContentApi.getNextId();

    final controller = StreamController<Uint8List>(
      onCancel: () {
        uriContentApi.cancelRequest(requestId);
      },
    );

    final readingStream = _nativeDataStream(
      uriSerializer(uri),
      requestId,
      params.bufferSize,
    );

    controller.addStream(readingStream).then((_) {
      controller.close();
    });

    yield* controller.stream;
  }

  @override
  Future<int?> getContentLength(Uri uri, UriSchemaHandlerParams params) {
    return uriContentApi.getContentLength(uriSerializer(uri));
  }
}
