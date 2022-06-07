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
, gzip                ? gzip
, ...
}@args:

( import ./setup-hooks { inherit makeSetupHook writeShellScriptBin; } ) //
( import ./trivial/tar.nix { inherit system gnutar gzip; } )

# NOTE: tsconfig.nix is intentionally excluded. Use `ak-nix.lib.tsconfig'.
