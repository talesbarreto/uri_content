import 'dart:io';

class InternalPlatform {
  final bool isAndroid;

  const InternalPlatform.internal(this.isAndroid);

  InternalPlatform() : isAndroid = Platform.isAndroid;
}
