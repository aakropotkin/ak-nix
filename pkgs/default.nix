{ lib, callPackage, makeSetupHook, writeShellScriptBin, ... }@args:
let merged =
  builtins.foldl' ( xs: sub: lib.recursiveUpdate xs ( import sub args ) ) {} [
    ./development
    ./build-support
  ];
in lib.filterAttrs ( _: val: lib.isDerivation val ) merged
