import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:uri_content/src/internal_platform.dart';
import 'package:uri_content/src/native_data_provider/uri_content_chunk_data.dart';
import 'package:uri_content/src/native_data_provider/uri_content_flutter_api_impl.dart';
import 'package:uri_content/src/uri_content_exception.dart';
import 'package:uri_content/uri_content.dart';

import 'src/native_data_provider/fake_uri_content_flutter_api_impl.dart';

UriContent _getUriContent({
  UriContentApi? uriContentApi,
  bool isAndroid = false,
}) {
  return UriContent(
    uriContentApi: uriContentApi ?? FakeUriContentApi(),
    internalPlatform: InternalPlatform.internal(isAndroid),
  );
}

void main() {
  const dataSample = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  final contentSchemeUri = Uri.parse("content://ha/he/hi/ho/hu");

  group("when `fromOrNull()` is invoked", () {
    test("return uri content", () async {
      final uriContent = _getUriContent();
      final uri = Uri.dataFromBytes(dataSample);
      expect(await uriContent.fromOrNull(uri), dataSample);
    });

    test("return null if exception is thrown on data get", () async {
      final uriContent = _getUriContent();
      expect(await uriContent.fromOrNull(contentSchemeUri), isNull);
    });
  });

  group("When scheme is 'content'", () {
    group("and platform is Android", () {
      test("request content to native API", () async {
        final api = FakeUriContentApi(
          newDataReceivedStream: const Stream.empty(),
        );
        final uriContent = _getUriContent(
          uriContentApi: api,
          isAndroid: true,
        );
        await uriContent.getContentStream(contentSchemeUri).drain();
        expect(api.requestedUris, contains(contentSchemeUri.toString()));
      });

      test("return a stream error if API returns an error", () {
        const error = "error!";
        final controller = StreamController<UriContentChunkData>();
        final uriContent = _getUriContent(
          uriContentApi: FakeUriContentApi(
            newDataReceivedStream: controller.stream,
          ),
          isAndroid: true,
        );
        expectLater(
          uriContent.getContentStream(contentSchemeUri),
          emitsError(
              predicate((e) => e is UriContentError && e.error == error)),
        );

        controller.add(
          const UriContentChunkData(requestId: 0, data: null, error: error),
        );
      });

      test("return data provided by API", () async {
        final controller = StreamController<UriContentChunkData>();
        final uriContent = _getUriContent(
          uriContentApi: FakeUriContentApi(
            newDataReceivedStream: controller.stream,
          ),
          isAndroid: true,
        );

        expectLater(
          uriContent.from(contentSchemeUri),
          completion(Uint8List.fromList([1, 2, 3, 4, 5, 6])),
        );

        controller.add(
          UriContentChunkData(
            requestId: 0,
            data: Uint8List.fromList([1, 2, 3]),
            error: null,
          ),
        );

        controller.add(
          UriContentChunkData(
            requestId: 1,
            data: Uint8List.fromList([10, 20, 30, 40, 50, 60]),
            error: null,
          ),
        );

        controller.add(
          UriContentChunkData(
            requestId: 0,
            data: Uint8List.fromList([4, 5, 6]),
            error: null,
          ),
        );

        controller.add(
          const UriContentChunkData(requestId: 0, data: null, error: null),
        );
      });
    });
  });
}
