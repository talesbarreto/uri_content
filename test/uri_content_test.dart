import 'package:flutter_test/flutter_test.dart';
import 'package:uri_content/uri_content.dart';

import 'src/native_data_provider/fake_uri_content_flutter_api_impl.dart';

UriContent _getUriContent() {
  return UriContent(
    uriContentApi: FakeUriContentApi(),
  );
}

void main() {
  const dataSample = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  group("when `fromOrNull()` is invoked", () {
    test("return uri content", () async {
      final uriContent = _getUriContent();
      final uri = Uri.dataFromBytes(dataSample);
      expect(await uriContent.fromOrNull(uri), dataSample);
    });

    test("return null if exception is thrown on data get", () async {
      final uriContent = _getUriContent();
      final uri = Uri.parse("content://ha/he/hi/ho/hu");
      expect(await uriContent.fromOrNull(uri), isNull);
    });
  });
}
