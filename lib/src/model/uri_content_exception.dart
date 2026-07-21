/// Base exception used by `uri_content` for known URI-content failures.
class UriContentError implements Exception {
  /// Human-readable error message.
  final String error;

  /// Creates an exception with the provided [error] message.
  const UriContentError(this.error);

  /// Thrown when a `data:` URI has no payload.
  static const dataSchemeWithNoData = UriContentError(
    "The URI has a data scheme, but its data is null.",
  );

  /// Thrown when a `content:` URI is used on a non-Android platform.
  static const contentOnlySupportedByAndroid = UriContentError(
    "`content` scheme is only supported on Android.",
  );

  @override
  String toString() => error;
}

/// Exception thrown when a URI scheme is not supported by this package.
class UnsupportedSchemeError implements UriContentError {
  @override
  /// Human-readable error message.
  final String error;

  /// Creates an error describing the unsupported URI [scheme].
  UnsupportedSchemeError(String scheme)
    : error =
          "scheme `$scheme` is not supported. "
          "Feel free to open an issue or submit an pull request at https://github.com/talesbarreto/uri_content";
}
