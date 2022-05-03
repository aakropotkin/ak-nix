{ lib, callPackage, makeSetupHook, writeShellScriptBin, ... }@args:
builtins.foldl' ( xs: sub: lib.recursiveUpdate xs ( import sub args ) ) {} [
  ./development
  ./build-support
]
