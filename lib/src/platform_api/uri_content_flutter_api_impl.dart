import 'dart:async';

import 'package:uri_content/src/platform_api/uri_content_native_api.dart';

class UriContentApi implements UriContentPlatformApi {
  final _api = UriContentPlatformApi();

  UriContentApi._();

  static final _instance = UriContentApi._();

  factory UriContentApi() => _instance;

  int _requestId = 0;

  int getNextId() => _requestId++;

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
