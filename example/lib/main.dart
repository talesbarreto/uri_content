import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uri_content/uri_content.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final uriContentFuture = Uri.parse(
          "https://raw.githubusercontent.com/talesbarreto/pull_request_coverage/main/README.md")
      .getContent()
      .then(utf8.decode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("uri_content example"),
        ),
        body: SingleChildScrollView(
          child: FutureBuilder<String>(
            future: uriContentFuture,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              return Text(snapshot.data ?? "No data");
            },
          ),
        ),
      ),
    );
  }
}
