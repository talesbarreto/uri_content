import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uri_content/uri_content.dart';
import 'package:uri_content_example/android_content/android_content_uri_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final uriStringFuture = Uri.parse(
    "https://raw.githubusercontent.com/talesbarreto/pull_request_coverage/main/README.md",
  ).getContent().then(utf8.decode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("pull_request_coverage readme")),
        body: FutureBuilder<String>(
          future: uriStringFuture,
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            return Markdown(
              data: snapshot.data ?? snapshot.connectionState.name,
              imageBuilder: (_, __, ___) => const SizedBox(),
            );
          },
        ),
        floatingActionButton: Visibility(
          visible: Theme.of(context).platform == TargetPlatform.android,
          child: Builder(
            builder:
                (context) => ElevatedButton(
                  child: const Text("Android's content example"),
                  onPressed: () => AndroidContentUriExample.push(context),
                ),
          ),
        ),
      ),
    );
  }
}
