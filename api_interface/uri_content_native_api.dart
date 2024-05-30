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
  @async
  void startRequest(String url, int requestId, int bufferSize);

  @async
  UriContentChunkResult requestNextChunk(int requestId);

  void cancelRequest(int requestId);

  @async
  int? getContentLength(String url);

  @async
  bool exists(String url);
}

class UriContentChunkResult {
  final Uint8List? chunk;
  final bool done;
  final String? error;

  const UriContentChunkResult(
    this.chunk,
    this.done,
    this.error,
  );
}
