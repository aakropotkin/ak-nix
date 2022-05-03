{ callPackage }:
( callPackage ./setup-hooks {} ) // {
  tsconfig-lib = callPackage ./tsconfig.nix {};
}
