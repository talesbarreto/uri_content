cd ..
flutter pub run pigeon \
  --input api_interface/uri_content_native_api.dart \
  --dart_out lib/src/native_api/uri_content_native_api.dart \
  --java_out android/src/main/kotlin/com/talesbarreto/uri_content/Api.java \
  --java_package "com.talesbarreto.uri_content"