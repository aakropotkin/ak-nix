{ lib ? ( builtins.getFlake "github:NixOS/nixpkgs?dir=lib" ).lib }:
lib.extend ( import ./overlay.lib.nix )
