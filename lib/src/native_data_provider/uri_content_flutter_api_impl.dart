import 'dart:async';
import 'dart:typed_data';

import 'package:uri_content/src/native_api/uri_content_native_api.dart';
import 'package:uri_content/src/native_data_provider/uri_content_chunk_data.dart';

class UriContentApi extends UriContentNativeApi
    implements UriContentFlutterApi {
  static final _instance = UriContentApi._();

  factory UriContentApi() => _instance;

  final _streamController = StreamController<UriContentChunkData>();

  late final newDataReceivedStream =
      _streamController.stream.asBroadcastStream();

  int _requestId = 0;

  int getNextId() => _requestId++;

  UriContentApi._() {
    UriContentFlutterApi.setup(this);
  }

  @override
  void onDataReceived(int requestId, Uint8List? data, String? error) {
    _streamController.add(
        UriContentChunkData(requestId: requestId, data: data, error: error));
  }

  void dispose() {
    _streamController.close();
  }
}
