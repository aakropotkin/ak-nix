{ flake-utils }:
let
  attrsets = import ./attrsets.nix { inherit flake-utils; };
in {
  inherit (attrsets) eachDefaultSystemMap eachAllSystemMap;
}
