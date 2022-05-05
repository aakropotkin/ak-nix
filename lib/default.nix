{ flake-utils
, nixpkgs-lib
}:
let
  attrsets = import ./attrsets.nix { inherit flake-utils; };
  paths    = import ./paths.nix { lib = nixpkgs-lib; };
  json     = import ./json.nix;
  strings  = import ./strings.nix { lib = nixpkgs-lib; };
in nixpkgs-lib // {  # Extend `nixpkgs.lib'

  inherit (attrsets) defaultSystemsMap allSystemsMap;
  # `nixpkgs.lib' has an `attrsets' member, so we need to extend theirs to
  # avoid wiping it out when updating `nixpkgs-lib' above.
  attrsets = nixpkgs-lib.attrsets // attrsets;

  inherit (json) readJSON;
  inherit json;

  inherit (paths) isAbsolutePath asAbspath extSuffix expandGlob;
  inherit paths;

  inherit (strings) matchingLines linesGrep readLines readLinesGrep readGrep;
  strings = nixpkgs-lib.strings // strings;

  tsconfig = import ../pkgs/build-support/tsconfig.nix {
    lib       = nixpkgs-lib;
    json-lib  = json;
    paths-lib = paths;
  };
}
