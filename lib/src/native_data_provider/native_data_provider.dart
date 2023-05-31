import 'dart:async';
import 'dart:typed_data';

import 'package:uri_content/src/native_api/uri_content_native_api.dart';
import 'package:uri_content/src/native_data_provider/uri_content_chunk_data.dart';

class NativeDataProvider implements UriContentFlutterApi {
  static final _instance = NativeDataProvider._();

  factory NativeDataProvider() => _instance;

  final _streamController = StreamController<UriContentChunkData>();

  late final stream = _streamController.stream.asBroadcastStream();

  NativeDataProvider._() {
    UriContentFlutterApi.setup(this);
  }

  @override
  void onDataReceived(int requestId, Uint8List? data, String? error) {
    _streamController.add(UriContentChunkData(requestId: requestId, data: data, error: error));
  }

  void dispose() {
    _streamController.close();
  }
}
