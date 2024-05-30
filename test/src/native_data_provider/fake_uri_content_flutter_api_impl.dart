import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uri_content/src/platform_api/uri_content_flutter_api_impl.dart';

class FakeUriContentApi extends Fake implements UriContentApi {
  @override
  int getNextId() => 0;

  FakeUriContentApi();

  final requestedUris = <String>[];

  @override
  Future<void> cancelRequest(int requestId) => SynchronousFuture(null);
}
