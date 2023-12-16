class UriContentError implements Exception {
  final String error;

  const UriContentError(this.error);

  static const dataSchemeWithNoData =
      UriContentError("The URI has a data scheme, but its data is null.");

  static const contentOnlySupportedByAndroid =
      UriContentError("`content` scheme is only supported on Android.");

  @override
  String toString() => error;
}

class UnsupportedSchemeError implements UriContentError {
  @override
  final String error;

  UnsupportedSchemeError(String scheme)
      : error = "scheme `$scheme` is not supported. "
            "Feel free to open an issue or submit an pull request at https://github.com/talesbarreto/uri_content";
}
