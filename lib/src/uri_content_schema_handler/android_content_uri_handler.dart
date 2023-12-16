import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uri_content/src/uri_content_schema_handler/uri_schema_handler.dart';

import '../../uri_content.dart';
import '../platform_api/uri_content_flutter_api_impl.dart';

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
      return uriContentApi.doesFileExist(uriSerializer(uri));
    } else {
      return SynchronousFuture(false);
    }
  }

  @override
  bool canHandle(Uri uri) {
    return uri.scheme == "content" && targetPlatform == TargetPlatform.android;
  }

  Stream<Uint8List> _currentRequestBytesStream(int requestId) async* {
    await for (final data in uriContentApi.newDataReceivedStream) {
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

  @override
  Stream<Uint8List> getContentStream(
    Uri uri,
    UriSchemaHandlerParams params,
  ) async* {
    final requestId = uriContentApi.getNextId();

    final controller = StreamController<Uint8List>(
      onListen: () {
        uriContentApi.getContentFromUri(
          uriSerializer(uri),
          requestId,
          params.bufferSize,
        );
      },
      onCancel: () {
        uriContentApi.cancelRequest(requestId);
      },
    );

    controller.addStream(_currentRequestBytesStream(requestId)).then((_) {
      controller.close();
    });

    yield* controller.stream;
  }
}
