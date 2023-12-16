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
          return GridView.builder(
            itemCount: photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
            ),
            itemBuilder: (BuildContext context, int index) {
              return FutureBuilder(
                future: widget.uriContent.from(photos[index]),
                builder: (context, snapshot) {
                  final error = snapshot.error;

                  if (error != null) {
                    return Center(
                      child: Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final image = snapshot.data;

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                    ),
                    child: image == null
                        ? const Center(child: CircularProgressIndicator())
                        : Image.memory(image),
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
