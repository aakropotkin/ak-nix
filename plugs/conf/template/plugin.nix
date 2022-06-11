# See instructions in `./default.nix'
{ system, writeText, myPlugin }: let
  platform = builtins.elemAt ( builtins.split "-" system ) 2;
  isDarwin = platform == "darwin";
  isLinux  = platform == "linux";
  libExt = if isDarwin then "dylib" else if isLinux then "so" else
    throw "Unknown platform: ${platform}. Unsure of which lib extension to use";
in writeText "myPlugin.conf" ''
  extra-plugin-files = ${myPlugin}/lib/libnix_doc_plugin.${libExt}
''
