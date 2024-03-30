import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: "lib/src/platform_api/uri_content_native_api.dart",
  kotlinOut:
      "android/src/main/kotlin/com/talesbarreto/uri_content/UriContentPlatformApi.kt",
  kotlinOptions: KotlinOptions(
    package: "com.talesbarreto.uri_content",
  ),
))
@HostApi()
abstract class UriContentPlatformApi {
  void requestContent(String url, int requestId, int bufferSize);

  void cancelRequest(int requestId);

  @async
  int? getContentLength(String url);

  @async
  bool doesFileExist(String url);
}

@FlutterApi()
abstract class UriContentFlutterApi {
  void onDataReceived(int requestId, Uint8List? data, String? error);
}
