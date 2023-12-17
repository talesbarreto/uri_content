import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uri_content/src/platform_api/uri_content_chunk_data.dart';
import 'package:uri_content/src/platform_api/uri_content_flutter_api_impl.dart';
import 'package:uri_content/src/uri_content_schema_handler/android_content_uri_handler.dart';
import 'package:uri_content/src/uri_content_schema_handler/uri_schema_handler.dart';

class MockUriContentApi extends Mock implements UriContentApi {}

void main() {
  final content1 = Uint8List.fromList(List.generate(
    1024,
    (index) => 1,
    growable: false,
  ));
  final content2 = Uint8List.fromList(List.generate(
    1024,
    (index) => 1 + 1024,
    growable: false,
  ));

  final uri = Uri.parse('content://test');
  late AndroidContentUriHandler handler;
  late MockUriContentApi mockUriContentApi;

  setUp(() {
    mockUriContentApi = MockUriContentApi();
    when(mockUriContentApi.getNextId).thenReturn(1);
    when(() => mockUriContentApi.cancelRequest(any()))
        .thenAnswer((invocation) => SynchronousFuture(null));
    when(() => mockUriContentApi.requestContent(any(), any(), any()))
        .thenAnswer((invocation) => SynchronousFuture(null));
    when(() => mockUriContentApi.newDataReceivedStream).thenAnswer(
      (invocation) => Stream.fromIterable([
        UriContentChunkData(requestId: 1, data: content1, error: null),
        UriContentChunkData(requestId: 2, data: content2, error: null),
        UriContentChunkData(requestId: 3, data: content2, error: null),
        UriContentChunkData(requestId: 1, data: content2, error: null),
        const UriContentChunkData(requestId: 1, data: null, error: null),
      ]),
    );
    handler = AndroidContentUriHandler(
      uriContentApi: mockUriContentApi,
      targetPlatform: TargetPlatform.android,
      uriSerializer: (uri) => uri.toString(),
    );
  });

  group("when canFetchContent is invoked", () {
    test('returns true when file exists on Android', () async {
      when(() => mockUriContentApi.doesFileExist(any()))
          .thenAnswer((_) async => true);
      expect(await handler.canFetchContent(uri, const UriSchemaHandlerParams()),
          isTrue);
    });

    test('returns false when file does not exist on Android', () async {
      when(() => mockUriContentApi.doesFileExist(any()))
          .thenAnswer((_) async => false);
      expect(await handler.canFetchContent(uri, const UriSchemaHandlerParams()),
          isFalse);
    });

    test('returns false when platform is not Android', () async {
      handler = AndroidContentUriHandler(
        uriContentApi: mockUriContentApi,
        targetPlatform: TargetPlatform.fuchsia,
        uriSerializer: (uri) => uri.toString(),
      );
      expect(await handler.canFetchContent(uri, const UriSchemaHandlerParams()),
          isFalse);
    });
  });

  group("when canHandle is invoked", () {
    test('returns true for content scheme on Android', () {
      expect(handler.canHandle(uri), isTrue);
    });

    test('returns false for non-content scheme on Android', () {
      final uri = Uri.parse('http://test');
      expect(handler.canHandle(uri), isFalse);
    });

    test('returns false for content scheme on non-Android platform', () {
      handler = AndroidContentUriHandler(
        uriContentApi: mockUriContentApi,
        targetPlatform: TargetPlatform.iOS,
        uriSerializer: (uri) => uri.toString(),
      );
      expect(handler.canHandle(uri), isFalse);
    });
  });

  group("when `getContentStream` is invoked", () {
    test("request content to native API", () async {
      await handler
          .getContentStream(uri, const UriSchemaHandlerParams())
          .drain();
      verify(() => mockUriContentApi.requestContent(any(), any(), any()))
          .called(1);
    });

    test("retrieve data from native API", () async {
      final stream =
          handler.getContentStream(uri, const UriSchemaHandlerParams());
      expect(await stream.toList(), [content1, content2]);
    });

    test("cancel request when stream is cancelled", () async {
      final stream =
          handler.getContentStream(uri, const UriSchemaHandlerParams());
      await stream.first;
      verify(() => mockUriContentApi.cancelRequest(any())).called(1);
    });
  });
}
