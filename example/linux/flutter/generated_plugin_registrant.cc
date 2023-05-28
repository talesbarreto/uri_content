//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <uri_content/uri_content_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) uri_content_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "UriContentPlugin");
  uri_content_plugin_register_with_registrar(uri_content_registrar);
}
