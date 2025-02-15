import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:uri_content/uri_content.dart';

class DataFetcher {
  final uriContent = UriContent();

  Future<(int? size, Uint8List data)> getData(Uri uri) async {
    return Future.wait([
      uriContent.getContentLength(uri),
      uriContent.from(uri),
    ]).then((value) {
      final size = value[0] as int?;
      final data = value[1] as Uint8List;
      return (size, data);
    });
  }

  // This method is used to fetch data from another isolate
  // It was written for testing purposes, intentionally overwhelming the
  // reading with multiple threads to test the performance and concurrency access.
  //
  // If you need to write a similar method, consider to use a pool of isolates
  // to read multiple files concurrently.
  Future<(int? size, Uint8List data)> getDataFromAnotherIsolate(Uri uri) async {
    final rootToken = RootIsolateToken.instance!;
    final port = ReceivePort();

    await Isolate.spawn(
      _fetch,
      DataFetcherInput(uri: uri, token: rootToken, sendPort: port.sendPort),
    );
    final result = await port.first;
    return result;
  }
}

class DataFetcherInput {
  final Uri uri;
  final RootIsolateToken token;
  final SendPort sendPort;

  const DataFetcherInput({
    required this.uri,
    required this.token,
    required this.sendPort,
  });
}

Future<void> _fetch(DataFetcherInput input) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(input.token);
  final uriContent = UriContent();

  final result = await Future.wait([
    uriContent.getContentLength(input.uri),
    uriContent.from(input.uri),
  ]);
  input.sendPort.send((result.first, result.last));
}
