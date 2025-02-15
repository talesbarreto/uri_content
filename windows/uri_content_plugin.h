#ifndef FLUTTER_PLUGIN_URI_CONTENT_PLUGIN_H_
#define FLUTTER_PLUGIN_URI_CONTENT_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace uri_content {

class UriContentPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  UriContentPlugin();

  virtual ~UriContentPlugin();

  // Disallow copy and assign.
  UriContentPlugin(const UriContentPlugin&) = delete;
  UriContentPlugin& operator=(const UriContentPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace uri_content

#endif  // FLUTTER_PLUGIN_URI_CONTENT_PLUGIN_H_
