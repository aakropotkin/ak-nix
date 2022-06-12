{
  description = "A handful of useful core utilities and scripts for Linux";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    utils.url   = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, utils }:
    let
      eachDefaultSystemMap = utils.lib.eachSystemMap utils.lib.defaultSystems;
      nonDefaultP = { n, _ }: n != "default";
      nonDefaultAttrs = attrset: nixpkgs.filterAttrs nonDefaultP attrset;
      nonDefaultValues = attrset: nixpkgs.lib.collect nonDefaultP attrset;
    in {
      packages = eachDefaultSystemMap ( system: rec {
        ak-core =
          ( import nixpkgs { inherit system; } ).callPackage ./default.nix {};
        default = ak-core;
      } );

      overlays =
        let
          packageOverlays = builtins.mapAttrs ( n: _: ( final: prev: {
            ${n} = self.packages.${final.system}.${n};
          } ) ) ( nonDefaultAttrs self.packages );
          nonPackageOverlays = {/* Add overlays */};
          overlayValues = ( builtins.attrValues packageOverlays ) ++
                          ( builtins.attrValues nonPackageOverlays );
        in packageOverlays // nonPackageOverlays // {
          default = final: prev:
            builtins.foldl' ( acc: o: acc // ( o final prev ) ) overlayValues;
        };

      #overlays.ak-core = final: prev: {
      #  inherit (self.packages.${final.system}) ak-core;
      #};
      #overlays.default = self.overlays.ak-core;

      nixosModules.ak-core = { ... }: {
        nixpkgs.overlays = builtins.attrValues self.overlays;
        /* Modules */
      };
      nixosModule = { ... }: {
        imports = builtins.attrValues self.nixosModules;
      };
    };
}
