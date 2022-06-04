{ nixpkgs             ? builtins.getFlake "nixpkgs"
, system              ? builtins.currentSystem
, pkgs                ? import nixpkgs.legacyPackages.${system}
, lib                 ? nixpkgs.lib
, callPackage         ? pkgs.callPackage
, makeSetupHook       ? pkgs.makeSetupHook
, writeShellScriptBin ? pkgs.makeShellScriptBin
, pandoc              ? pkgs.pandoc
, texinfo             ? pkgs.texinfo
, ...
}@args:
let merged =
  builtins.foldl' ( xs: sub: lib.recursiveUpdate xs ( import sub args ) ) {} [
    ./development
    ./build-support
    ./docgen
  ];
in lib.filterAttrs ( _: val: lib.isDerivation val ) merged
