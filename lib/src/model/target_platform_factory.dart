import 'dart:io';

import 'package:flutter/services.dart';

TargetPlatform getTargetPlatform() {
  switch (Platform.operatingSystem) {
    case "android":
      return TargetPlatform.android;
    case "ios":
      return TargetPlatform.iOS;
    case "linux":
      return TargetPlatform.linux;
    case "macos":
      return TargetPlatform.macOS;
    case "windows":
      return TargetPlatform.windows;
    case "fuchsia":
      return TargetPlatform.fuchsia;
    default:
      throw UnsupportedError(
          "Unsupported platform ${Platform.operatingSystem}");
  }
}
