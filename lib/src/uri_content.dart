import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uri_content/src/model/target_platform_factory.dart';

import 'platform_api/uri_content_flutter_api_impl.dart';
import 'uri_content_schema_handler/android_content_uri_handler.dart';
import 'uri_content_schema_handler/data_uri_handler.dart';
import 'uri_content_schema_handler/fallback_uri_handler.dart';
import 'uri_content_schema_handler/file_uri_handler.dart';
import 'uri_content_schema_handler/http_uri_handler.dart';
import 'uri_content_schema_handler/uri_schema_handler.dart';

typedef UriSerializer = String Function(Uri uri);

extension UriContentGetter on Uri {
  /// The [getContent] extension simplifies the process of retrieving content from a Uri.
  /// If you don't mind disregarding clean architecture or code testability, you can use it directly.
  /// However, if you prefer a more flexible approach, you can utilize [UriContent] to make it injectable and mockable.
  ///
  /// Note that [getContent] will throw an exception if it is not possible to retrieve the content.
  Future<Uint8List> getContent() => UriContent().from(this);

  /// same as [getContent] but return `null` on errors.
  Future<Uint8List?> getContentOrNull() => UriContent().fromOrNull(this);
}

class UriContent {
  final List<UriSchemaHandler> schemaHandlers;

  const UriContent.internal(this.schemaHandlers);

  static String _defaultUriSerializer(Uri uri) => uri.toString();

  /// [defaultHttpHeaders] see https://api.flutter.dev/flutter/dart-io/HttpHeaders/add.html
  UriContent({
    Map<String, Object> defaultHttpHeaders = const {},
    HttpClient? httpClient,
    UriSerializer uriSerializer = _defaultUriSerializer,
    UriContentApi? uriContentApi,
    TargetPlatform? internalPlatform,
  }) : schemaHandlers = [
          const DataUriHandler(),
          const FileUriHandler(),
          HttpUriHandler(
            httpClient: httpClient ?? HttpClient(),
            defaultHttpHeaders: defaultHttpHeaders,
          ),
          AndroidContentUriHandler(
            uriContentApi: uriContentApi ?? UriContentApi(),
            targetPlatform: internalPlatform ?? getTargetPlatform(),
            uriSerializer: uriSerializer,
          ),
        ];

  /// Get the content from an Uri.
  /// Supported schemes: data, file, http, https, Android content
  ///
  ///
  /// [httpHeaders] see https://api.flutter.dev/flutter/dart-io/HttpHeaders/add.html
  ///
  /// Throws exception if it was nos possible to get the content
  ///
  /// Consider using [getContentStream] if you are retrieving a large file
  Future<Uint8List> from(
    Uri uri, {
    Map<String, Object> httpHeaders = const {},
  }) {
    return getContentStream(uri, httpHeaders: httpHeaders).fold(
      Uint8List(0),
      (previous, element) => Uint8List.fromList([...previous, ...element]),
    );
  }

  /// same as [getContentStream] but returns `null` on errors.
  Future<Uint8List?> fromOrNull(
    Uri uri, {
    Map<String, Object> httpHeaders = const {},
  }) async {
    try {
      final result = await from(uri, httpHeaders: httpHeaders);
      return result;
    } catch (e) {
      return null;
    }
  }

  UriSchemaHandler _getUriSchemaHandler(Uri uri) {
    return schemaHandlers.firstWhere(
      (handler) => handler.canHandle(uri),
      orElse: () => const FallbackUriHandler(),
    );
  }

  /// [getContentStream] returns a Stream of Uint8List where each event represents a chunk of the content from the specified URI.
  /// This approach is more suitable when you don't need the entire content at once, such as in a request provider or
  /// when directly saving the bytes into a File.
  /// Handling small chunks significantly reduces memory consumption.
  ///
  /// [httpHeaders] see https://api.flutter.dev/flutter/dart-io/HttpHeaders/add.html
  ///
  /// [bufferSize] sets the total of bytes to be send on each stream event. It ONLY affects `android content` Uris
  ///
  /// Warning: To prevent resource leaks, make sure to either listen to the stream until the end or close it
  /// if you want to abort the content reading.
  Stream<Uint8List> getContentStream(
    Uri uri, {
    int bufferSize = UriSchemaHandlerParams.defaultBufferSize,
    Map<String, Object> httpHeaders = const {},
  }) async* {
    final handler = _getUriSchemaHandler(uri);

    final params = UriSchemaHandlerParams(
      bufferSize: bufferSize,
      httpHeaders: httpHeaders,
    );

    yield* handler.getContentStream(uri, params);
  }

  /// [canFetchContent] checks if it is possible to fetch the content from the specified Uri.
  /// If it is a file, it checks if it exists.
  /// If it is a http/https Uri, it checks if it is reachable.
  Future<bool> canFetchContent(
    Uri uri, {
    Map<String, Object> httpHeaders = const {},
  }) {
    final handler = _getUriSchemaHandler(uri);

    final params = UriSchemaHandlerParams(
      httpHeaders: httpHeaders,
    );
    return handler.canFetchContent(uri, params);
  }

  /// [getContentLength] returns the content length in bytes of the specified Uri.
  /// It relies on metadata to get the content length, so it may NOT be accurate.
  ///
  /// It may throw an exception if the content is not reachable.
  ///
  /// If the content length is not available, it returns `null`.
  ///
  /// Use [getContentLengthOrNull] if you don't want to handle exceptions.
  Future<int?> getContentLength(
    Uri uri, {
    Map<String, Object> httpHeaders = const {},
  }) {
    final handler = _getUriSchemaHandler(uri);

    final params = UriSchemaHandlerParams(
      httpHeaders: httpHeaders,
    );
    return handler.getContentLength(uri, params);
  }

  /// Similar to [getContentLength] but return `null` on errors.
  ///
  /// Note that `null` is ambiguous; it may indicate that the content is not reachable or the content length is unavailable.
  /// Hence, it is recommended to use [getContentLength] and handle its exceptions.
  Future<int?> getContentLengthOrNull(
    Uri uri, {
    Map<String, Object> httpHeaders = const {},
  }) async {
    try {
      final result = await getContentLength(uri, httpHeaders: httpHeaders);
      return result;
    } catch (e) {
      return null;
    }
  }
}
