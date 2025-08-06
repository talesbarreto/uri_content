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
  /// [registerRequest] prepares a request on Android side, persisting its parameters and returning immediately.
  /// After this method is called, the client can start calling [requestNextChunk] to get the next chunk of data, that will have at most [bufferSize] bytes.
  /// The [requestId] is used to identify the request in subsequent calls to [requestNextChunk] and [cancelRequest].
  /// The [url] is the content URI to be accessed.
  /// The [bufferSize] is the maximum size of each chunk of data to be returned, it also defines the size of the internal buffer used to read data from the content URI on the Android side.
  @async
  void registerRequest(String url, int requestId, int bufferSize);

  /// [requestNextChunk] releases the Android side to read the next chunk of data from the content URI associated with the given [requestId].
  /// It returns a [UriContentChunkResult] that contains the next chunk of data, or an error if something went wrong.
  /// After the chunk is read, the Android side will wait until this method is called again to read the next chunk.
  @async
  UriContentChunkResult requestNextChunk(int requestId);

  /// [cancelRequest] cancels the request associated with the given [requestId], releasing any resources associated with it on the Android side.
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
