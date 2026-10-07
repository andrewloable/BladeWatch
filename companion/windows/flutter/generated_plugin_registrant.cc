//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_pear_bare/flutter_pear_bare_plugin.h>
#include <local_auth_windows/local_auth_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FlutterPearBarePluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterPearBarePlugin"));
  LocalAuthPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("LocalAuthPlugin"));
}
