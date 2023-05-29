import 'dart:async';

import 'package:flutter/foundation.dart';

class ContentRequest {
  final Completer<Uint8List> completer;
  List<Uint8List> data;

  ContentRequest({
    required this.completer,
    required this.data,
  });
}
