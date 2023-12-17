import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uri_content/src/platform_api/uri_content_chunk_data.dart';
import 'package:uri_content/src/platform_api/uri_content_flutter_api_impl.dart';

class FakeUriContentApi extends Fake implements UriContentApi {
  @override
  final Stream<UriContentChunkData> newDataReceivedStream;

  @override
  int getNextId() => 0;

  FakeUriContentApi({this.newDataReceivedStream = const Stream.empty()});

  final requestedUris = <String>[];

  @override
  Future<void> requestContent(
    String url,
    int requestId,
    int bufferSize,
  ) {
    requestedUris.add(url);
    return SynchronousFuture(null);
  }

  @override
  Future<void> cancelRequest(int requestId) => SynchronousFuture(null);
}
