import 'dart:io';

import 'package:flutter/services.dart';

TargetPlatform getTargetPlatform() {
  return switch (Platform.operatingSystem) {
    "android" => TargetPlatform.android,
    "ios" => TargetPlatform.iOS,
    "linux" => TargetPlatform.linux,
    "macos" => TargetPlatform.macOS,
    "windows" => TargetPlatform.windows,
    "fuchsia" => TargetPlatform.fuchsia,
    _ => throw UnsupportedError(
        "Unsupported platform ${Platform.operatingSystem}"),
  };
}
