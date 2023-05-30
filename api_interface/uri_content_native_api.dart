import 'package:pigeon/pigeon.dart';

@HostApi()
abstract class UriContentNativeApi {
  void getContentFromUri(String url, int requestId, int bufferSize);
}

@FlutterApi()
abstract class UriContentFlutterApi {
  void onDataReceived(int requestId, Uint8List? data, String? error);
}
