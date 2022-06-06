{ nixpkgs-lib ? ( builtins.getFlake "nixpkgs" ).lib
, flake-utils ? builtins.getFlake "github:numtide/flake-utils"
}:
let
  libattrs = import ./attrsets.nix { inherit flake-utils; };
  libpath  = import ./paths.nix { lib = nixpkgs-lib; };
  libjson  = import ./json.nix;
  libstr   = import ./strings.nix { lib = nixpkgs-lib; };
  libfs    = import ./filesystem.nix;
  librepl  = import ./repl.nix { inherit libfs libpath; lib = nixpkgs-lib; };
  liblist  = import ./lists.nix { lib = nixpkgs-lib; };

  lib = nixpkgs-lib.extend ( final: prev:
    let callLibs = file: import file { lib = final; };
    in {
      libattrs = import   ./attrsets.nix { lib = final; inherit flake-utils; };
      libpath  = callLibs ./paths.nix;
      libjson  = callLibs ./json.nix;
      libstr   = callLibs ./strings.nix;
      libfs    = callLibs ./filesystem.nix;
      librepl  = callLibs ./repl.nix;
      liblist  = callLibs ./lists.nix;

      inherit (libattrs) defaultSystemsMap allSystemsMap;

      inherit (libjson) importJSON';

      inherit (libpath) isAbsolutePath asAbspath extSuffix expandGlob;
      inherit (libpath) realpathRel;

      inherit (libstr) matchingLines linesGrep readLines readLinesGrep readGrep;
      inherit (libstr) charN;

      inherit (libfs) baseName';

      inherit (librepl) show ls pwd;

      inherit (liblist) takeUntil dropUntil;

    } );
in lib
