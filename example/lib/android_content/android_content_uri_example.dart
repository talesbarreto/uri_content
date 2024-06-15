import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uri_content_example/android_content/data_fetcher.dart';
import 'package:uri_content_example/android_content/android_photos_fetcher.dart';

class AndroidContentUriExample extends StatefulWidget {
  final AndroidPhotosFetcher androidPhotosFetcher;

  const AndroidContentUriExample({
    super.key,
    required this.androidPhotosFetcher,
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
          builder: (context) => const AndroidContentUriExample(
            androidPhotosFetcher: AndroidPhotosFetcher(),
          ),
        ),
      );
    }
  }
}

class _AndroidContentUriExampleState extends State<AndroidContentUriExample> {
  final _dataFetcher = DataFetcher();
  late final photosFuture = widget.androidPhotosFetcher.getPhotos();

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
            itemCount: photos.length,
            itemBuilder: (BuildContext context, int index) {
              return FutureBuilder(
                future: _dataFetcher.getData(photos[index]),
                builder: (BuildContext context,
                    AsyncSnapshot<(int? size, Uint8List data)> snapshot) {
                  final size = snapshot.data?.$1;
                  final data = snapshot.data?.$2;

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 300),
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
