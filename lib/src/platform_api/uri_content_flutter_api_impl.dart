import 'dart:async';
import 'dart:math' as math;
import 'package:uri_content/src/platform_api/uri_content_native_api.dart';

class UriContentApi {
  final _random = math.Random();
  final _api = UriContentPlatformApi();

  int getNextId() => _random.nextInt(1 << 32);

  Future<void> cancelRequest(int requestId) {
    return _api.cancelRequest(requestId);
  }

  Future<bool> exists(String url) {
    return _api.exists(url);
  }

  Future<int?> getContentLength(String url) {
    return _api.getContentLength(url);
  }

  Future<UriContentChunkResult> requestNextChunk(int requestId) {
    return _api.requestNextChunk(requestId);
  }

  Future<void> registerRequest(String url, int requestId, int bufferSize) {
    return _api.registerRequest(url, requestId, bufferSize);
  }
}
