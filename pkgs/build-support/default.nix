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
, bash                ? bash
, ...
}@args:

( import ./setup-hooks { inherit makeSetupHook writeShellScriptBin; } ) //
( import ./trivial/tar.nix { inherit system gnutar gzip; } ) //
# DO NOT PASS `nixpkgs.lib' to `link.nix', it needs `libfs'.
( import ./trivial/link.nix { inherit system coreutils bash; } )

# NOTE: tsconfig.nix is intentionally excluded. Use `ak-nix.lib.tsconfig'.
