{ flake-utils, nixpkgs-lib }:
let
  libattrs = import ./attrsets.nix { inherit flake-utils; };
  libpath  = import ./paths.nix { lib = nixpkgs-lib; };
  libjson  = import ./json.nix;
  libstr   = import ./strings.nix { lib = nixpkgs-lib; };
  libfs    = import ./filesystem.nix;
  librepl  = import ./repl.nix { inherit libfs libpath; lib = nixpkgs-lib; };
  liblist  = import ./lists.nix { lib = nixpkgs-lib; };
in nixpkgs-lib // {  # Extend `nixpkgs.lib'
  inherit libattrs libpath libjson libstr libfs librepl;

  inherit (libattrs) defaultSystemsMap allSystemsMap;
  inherit (libjson) readJSON;
  inherit (libpath) isAbsolutePath asAbspath extSuffix expandGlob;
  inherit (libstr) matchingLines linesGrep readLines readLinesGrep readGrep;
  inherit (librepl) show ls pwd;

  tsconfig = import ../pkgs/build-support/tsconfig.nix {
    lib = nixpkgs-lib;
    inherit libjson libpath;
  };
}
