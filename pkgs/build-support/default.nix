{ lib, callPackage, makeSetupHook, writeShellScriptBin, ... }@args:
( import ./setup-hooks args ) // {
  tsconfig-lib = import ./tsconfig.nix { inherit lib; };
}
