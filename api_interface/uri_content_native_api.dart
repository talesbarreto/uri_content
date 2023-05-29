import 'package:pigeon/pigeon.dart';

@HostApi()
abstract class UriContentNativeApi {
  void getContentFromUri(String url, int requestId);
}

@FlutterApi()
abstract class UriContentFlutterApi {
  void onDataReceived(int requestId, Uint8List? data, String? error);
}
