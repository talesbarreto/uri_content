import 'package:flutter/services.dart';

class AndroidPhotosFetcher {
  static const platform = MethodChannel('com.talesbarreto.uri_content/example');

  const AndroidPhotosFetcher();

  Future<List<Uri>> getPhotos() async {
    final List<dynamic> photos =
        await platform.invokeMethod('getPhotosUrisFromMediaStore');
    return photos
        .cast<String>()
        .map((e) => Uri.parse(e))
        .toList(growable: false);
  }
}
