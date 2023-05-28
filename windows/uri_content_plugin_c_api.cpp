#include "include/uri_content/uri_content_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "uri_content_plugin.h"

void UriContentPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  uri_content::UriContentPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
