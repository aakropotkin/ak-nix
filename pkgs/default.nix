{ lib , callPackage }:
builtins.foldl ( subdir: lib.recursiveUpdate ( callPackage subdir {} ) ) {} [
  ./development
  ./build-support
]
