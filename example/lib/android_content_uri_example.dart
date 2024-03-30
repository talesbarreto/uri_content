import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uri_content/uri_content.dart';
import 'package:uri_content_example/android_photos_fetcher.dart';

class AndroidContentUriExample extends StatefulWidget {
  final UriContent uriContent;
  final AndroidPhotosFetcher androidPhotosFetcher;

  const AndroidContentUriExample({
    super.key,
    required this.androidPhotosFetcher,
    required this.uriContent,
  });

  @override
  State<AndroidContentUriExample> createState() =>
      _AndroidContentUriExampleState();

  static Future<bool> _requestPermission() async {
    final result = await Permission.photos.request();
    return result == PermissionStatus.granted;
  }

  static Future<void> push(BuildContext context) async {
    if (await _requestPermission() && context.mounted) {
      return Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => AndroidContentUriExample(
            androidPhotosFetcher: const AndroidPhotosFetcher(),
            uriContent: UriContent(),
          ),
        ),
      );
    }
  }
}

class _AndroidContentUriExampleState extends State<AndroidContentUriExample> {
  late final photosFuture = widget.androidPhotosFetcher.getPhotos();

  Future<(int? size, Uint8List data)> _getData(Uri uri) async {
    return Future.wait([
      widget.uriContent.getContentLength(uri),
      widget.uriContent.from(uri),
    ]).then((value) {
      final size = value[0] as int?;
      final data = value[1] as Uint8List;
      return (size, data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Uri>>(
        future: photosFuture,
        builder: (context, AsyncSnapshot<List<Uri>> snapshot) {
          final photos = snapshot.data;
          if (photos == null) {
            return const CircularProgressIndicator();
          }

          return ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              return FutureBuilder(
                future: _getData(photos[index]),
                builder: (BuildContext context,
                    AsyncSnapshot<(int? size, Uint8List data)> snapshot) {
                  final size = snapshot.data?.$1;
                  final data = snapshot.data?.$2;

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      child: Container(
                        constraints: const BoxConstraints(
                          maxHeight: 300
                        ),
                        child: Column(
                          children: [
                            Text(
                              size == null
                                  ? 'Unknown size'
                                  : '${size ~/ 1024} KB',
                            ),
                            data == null
                                ? const CircularProgressIndicator()
                                : Flexible(
                                    child: Image.memory(
                                      data,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
