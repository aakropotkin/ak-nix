{ lib , callPackage }:
builtins.foldl' ( xs: sub: lib.recursiveUpdate xs ( callPackage sub {} ) ) {} [
  ./development
  ./build-support
]
