import 'package:pigeon/pigeon.dart';

@HostApi()
abstract class UriContentNativeApi {
  Uint8List getContentFromUri(String url);
}
