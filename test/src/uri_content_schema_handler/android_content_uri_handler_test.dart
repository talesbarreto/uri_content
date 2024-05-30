import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uri_content/src/platform_api/uri_content_flutter_api_impl.dart';
import 'package:uri_content/src/platform_api/uri_content_native_api.dart';
import 'package:uri_content/src/uri_content_schema_handler/android_content_uri_handler.dart';
import 'package:uri_content/src/uri_content_schema_handler/uri_schema_handler.dart';

class MockUriContentApi extends Mock implements UriContentApi {}

void main() {
  final uri = Uri.parse('content://test');
  late AndroidContentUriHandler handler;
  late MockUriContentApi mockUriContentApi;

  setUp(() {
    mockUriContentApi = MockUriContentApi();
    when(mockUriContentApi.getNextId).thenReturn(1);
    when(() => mockUriContentApi.cancelRequest(any()))
        .thenAnswer((invocation) => SynchronousFuture(null));
    when(() => mockUriContentApi.startRequest(any(), any(), any()))
        .thenAnswer((invocation) => SynchronousFuture(null));
    handler = AndroidContentUriHandler(
      uriContentApi: mockUriContentApi,
      targetPlatform: TargetPlatform.android,
      uriSerializer: (uri) => uri.toString(),
    );
  });

  group("when canFetchContent is invoked", () {
    test('returns true when file exists on Android', () async {
      when(() => mockUriContentApi.exists(any())).thenAnswer((_) async => true);
      expect(await handler.canFetchContent(uri, const UriSchemaHandlerParams()),
          isTrue);
    });

    test('returns false when file does not exist on Android', () async {
      when(() => mockUriContentApi.exists(any()))
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
    late List<Uint8List> content;

    setUp(() {
      content = [
        Uint8List.fromList([1, 2, 3, 4]),
        Uint8List.fromList([5, 6, 7, 8]),
        Uint8List.fromList([9, 10, 11, 12]),
      ];

      when(() => mockUriContentApi.startRequest(any(), any(), any()))
          .thenAnswer((invocation) => SynchronousFuture(null));

      when(() => mockUriContentApi.requestNextChunk(any())).thenAnswer(
        (invocation) => SynchronousFuture(
          UriContentChunkResult(
            done: content.isEmpty,
            chunk: content.isEmpty ? null : content.removeAt(0),
          ),
        ),
      );
    });

    group("and stream is entirely read", () {
      test("invoke `startRequest` only once", () async {
        await handler
            .getContentStream(uri, const UriSchemaHandlerParams())
            .toList();

        verify(() => mockUriContentApi.startRequest(any(), any(), any()))
            .called(1);
      });

      test("invoke `requestNextChunk` until the last chunk", () async {
        await handler
            .getContentStream(uri, const UriSchemaHandlerParams())
            .toList();

        verify(() => mockUriContentApi.requestNextChunk(any())).called(4);
      });

      test("returns the content in the correct order", () async {
        final stream = await handler
            .getContentStream(uri, const UriSchemaHandlerParams())
            .fold(
              Uint8List(0),
              (previous, element) =>
                  Uint8List.fromList([...previous, ...element]),
            );

        expect(stream, equals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]));
      });

      test("invoke `cancelRequest`", () async {
        await handler
            .getContentStream(uri, const UriSchemaHandlerParams())
            .toList();

        verify(() => mockUriContentApi.cancelRequest(any())).called(1);
      });
    });

    group("and stream is cancelled", () {
      test("do not invoke `requestNextChunk`", () async {
        final stream =
            handler.getContentStream(uri, const UriSchemaHandlerParams());

        await for (final _ in stream) {
          break;
        }

        verify(() => mockUriContentApi.requestNextChunk(any())).called(1);
      });

      test("invoke `cancelRequest`", () async {
        final stream =
            handler.getContentStream(uri, const UriSchemaHandlerParams());

        await for (final _ in stream) {
          break;
        }

        verify(() => mockUriContentApi.cancelRequest(any())).called(1);
      });
    });

    group("and an error is emitted", () {
      setUp(() {
        when(() => mockUriContentApi.requestNextChunk(any()))
            .thenThrow(Exception("test exception"));
      });

      test("invoke `cancelRequest`", () async {
        await handler
            .getContentStream(uri, const UriSchemaHandlerParams())
            .first
            .onError((_, __) => Uint8List(0));

        verify(() => mockUriContentApi.cancelRequest(any())).called(1);
      });
    });
  });
}
