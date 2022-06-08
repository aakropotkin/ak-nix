{ nixpkgs             ? builtins.getFlake "nixpkgs"
, system              ? builtins.currentSystem
, pkgs                ? nixpkgs.legacyPackages.${system}
, lib                 ? nixpkgs.lib
, callPackage         ? pkgs.callPackage
, makeSetupHook       ? pkgs.makeSetupHook
, writeShellScriptBin ? pkgs.makeShellScriptBin
, pandoc              ? pkgs.pandoc
, texinfo             ? pkgs.texinfo
, gnutar              ? pkgs.gnutar
, gzip                ? pkgs.gzip
, coreutils           ? pkgs.coreutils
, bash                ? pkgs.bash
, ...
}@args:
let merged =
  builtins.foldl' ( xs: sub: lib.recursiveUpdate xs ( import sub args ) ) {} [
    ./development
    ./build-support
    ./docgen
  ];
in lib.filterAttrs ( _: val: lib.isDerivation val ) merged
