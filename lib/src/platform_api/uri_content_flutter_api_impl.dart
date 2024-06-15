import 'dart:async';
import 'dart:math' as math;

import 'package:uri_content/src/platform_api/uri_content_native_api.dart';

class UriContentApi implements UriContentPlatformApi {
  final _random = math.Random();
  final _api = UriContentPlatformApi();

  int getNextId() => _random.nextInt(1 << 32);

  @override
  Future<void> cancelRequest(int requestId) {
    return _api.cancelRequest(requestId);
  }

  @override
  Future<bool> exists(String url) {
    return _api.exists(url);
  }

  @override
  Future<int?> getContentLength(String url) {
    return _api.getContentLength(url);
  }

  @override
  Future<UriContentChunkResult> requestNextChunk(int requestId) {
    return _api.requestNextChunk(requestId);
  }

  @override
  Future<void> startRequest(String url, int requestId, int bufferSize) {
    return _api.startRequest(url, requestId, bufferSize);
  }
}
