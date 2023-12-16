import 'dart:typed_data';

class UriContentChunkData {
  final int requestId;
  final Uint8List? data;
  final String? error;

  const UriContentChunkData({
    required this.requestId,
    required this.data,
    required this.error,
  });
}
