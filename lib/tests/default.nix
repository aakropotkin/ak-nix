{ lib       ? ( builtins.getFlake ( toString ../.. ) ).lib
, withDrv   ? true
, nixpkgs   ? builtins.getFlake "nixpkgs"
, system    ? builtins.currentSystem
, pkgs      ? nixpkgs.legacyPackages.${system}
, writeText ? pkgs.writeText
, ...
} @ args: let
  inputs = args // { inherit lib withDrv nixpkgs system pkgs writeText; };
  checkFile = file:
    builtins.trace "Checking ${file}"
                   ( import ( ./. +  "/${file}" ) inputs ).checkDrv;
  checkAll = pkgs.linkFarmFromDrvs "tests-all" [
    ( checkFile "strings.nix" )
    ( checkFile "debug.nix" )
    ( checkFile "paths.nix" )
  ];
in checkAll
