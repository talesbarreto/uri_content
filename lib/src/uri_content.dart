import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  /// [getContent] simplifies retrieving content from a Uri.
  /// You can call it directly for convenience.
  /// For better testability and dependency injection, use [UriContent] directly.
  ///
  /// Throws an exception when content cannot be retrieved.
  Future<Uint8List> getContent() => UriContent().from(this);

  /// Same as [getContent], but returns `null` on errors.
  Future<Uint8List?> getContentOrNull() => UriContent().fromOrNull(this);
}

class UriContent {
  final List<UriSchemaHandler> schemaHandlers;

  const UriContent.internal(this.schemaHandlers);

  static String _defaultUriSerializer(Uri uri) => uri.toString();

  /// [defaultHttpHeaders]: https://api.flutter.dev/flutter/dart-io/HttpHeaders/add.html
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

  /// Retrieves content from a Uri.
  /// Supported schemes: data, file, http, https, and Android content.
  ///
  /// [httpHeaders]: https://api.flutter.dev/flutter/dart-io/HttpHeaders/add.html
  ///
  /// Throws an exception if content cannot be retrieved.
  ///
  /// Consider using [getContentStream] when retrieving large files.
  Future<Uint8List> from(
    Uri uri, {
    Map<String, Object> httpHeaders = const {},
  }) {
    return getContentStream(uri, httpHeaders: httpHeaders).fold(
      Uint8List(0),
      (previous, element) => Uint8List.fromList([...previous, ...element]),
    );
  }

  /// Same as [from], but returns `null` on errors.
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

  /// Returns a stream of [Uint8List], where each event is a chunk of content from
  /// the specified Uri.
  /// This is useful when you do not need the entire content at once, such as when
  /// forwarding data to another request or writing directly to a [File].
  /// Processing chunks reduces peak memory usage.
  ///
  /// [httpHeaders]: https://api.flutter.dev/flutter/dart-io/HttpHeaders/add.html
  ///
  /// [bufferSize] sets how many bytes are sent per stream event.
  /// It only affects `android content` URIs.
  /// The default is 5 MB. Lower values reduce memory usage; higher values can
  /// improve throughput.
  ///
  /// To prevent resource leaks, consume the stream to completion or cancel the
  /// subscription when aborting content reading.
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

  /// Checks whether content can be fetched from the specified Uri.
  /// For `file` URIs, this checks whether the file exists.
  /// For `http`/`https` URIs, this checks whether the resource is reachable.
  Future<bool> canFetchContent(
    Uri uri, {
    Map<String, Object> httpHeaders = const {},
  }) {
    final handler = _getUriSchemaHandler(uri);

    final params = UriSchemaHandlerParams(httpHeaders: httpHeaders);
    return handler.canFetchContent(uri, params);
  }

  /// Returns the content length in bytes for the specified Uri.
  /// This relies on metadata, so it may be inaccurate.
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

    final params = UriSchemaHandlerParams(httpHeaders: httpHeaders);
    return handler.getContentLength(uri, params);
  }

  /// Similar to [getContentLength], but returns `null` on errors.
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
