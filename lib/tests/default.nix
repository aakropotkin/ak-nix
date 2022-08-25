# =========================================================================== #

{ lib              ? ( builtins.getFlake "${toString ../..}" ).lib
, nixpkgs          ? builtins.getFlake "nixpkgs"
, system           ? builtins.currentSystem
, pkgsFor          ? nixpkgs.legacyPackages.${system}
, writeText        ? pkgsFor.writeText
, linkFarmFromDrvs ? pkgsFor.linkFarmFromDrvs
, ...
} @ args: let
  inputs = args // { inherit lib nixpkgs system pkgsFor writeText; };
  checkFile = file:
    builtins.trace "Checking ${file}"
                   ( import ( ./. +  "/${file}" ) inputs ).checkDrv;
  checkAll = linkFarmFromDrvs "tests-all" [
    ( checkFile "strings.nix" )
    ( checkFile "debug.nix" )
    ( checkFile "paths.nix" )
  ];
in checkAll


# --------------------------------------------------------------------------- #
#
#
#
# =========================================================================== #
