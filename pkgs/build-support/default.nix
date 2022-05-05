{ lib, callPackage, makeSetupHook, writeShellScriptBin, ... }@args:
( import ./setup-hooks args )
# NOTE: tsconfig.nix is intentionally excluded. Use `ak-nix.lib.tsconfig'.
