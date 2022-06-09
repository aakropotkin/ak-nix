{ lib ? ( builtins.getFlake "nixpkgs" ).lib
, utils ? builtins.getFlake "github:numtide/flake-utils"
}:
let
  lib' = lib.extend ( final: prev:
    let callLibs = file: import file { lib = final; };
    in {
      libattrs = import   ./attrsets.nix { lib = final; inherit utils; };
      libpath  = callLibs ./paths.nix;
      libjson  = callLibs ./json.nix;
      libstr   = callLibs ./strings.nix;
      libfs    = callLibs ./filesystem.nix;
      librepl  = callLibs ./repl.nix;
      liblist  = callLibs ./lists.nix;

      inherit (final.libattrs)
        currySystems curryDefaultSystems funkSystems funkDefaultSystems
        attrsToList;

      inherit (final.libjson) importJSON';

      inherit (final.libpath) isAbsolutePath asAbspath extSuffix expandGlob;
      inherit (final.libpath) realpathRel;

      inherit (final.libstr) matchingLines readLines charN;
      inherit (final.libstr) linesGrep readGrep readLinesGrep;

      inherit (final.libfs) baseName';

      inherit (final.librepl) show ls pwd;

      inherit (final.liblist) takeUntil dropUntil;
    } );
in lib'
