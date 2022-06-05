/**
 * NOTE:
 *  In retrospect, merging flakes like this was really dumb.
 *  I was basically reinventing a `registry.json' but in a much uglier way.
 *  This should get gutted soon, and flakes should be imported where they
 *  are actually used.
 *  By merging flakes, managing lockfiles becomes incredibly tedious, and I
 *  do not recommend that any readers look at this flake as "good practice".
 */
{
  description = "A collection of aakropotkin's nix flakes";

  inputs = {
    set_wm_class.url = "github:aakropotkin/set_wm_class";
    set_wm_class.inputs.nixpkgs.follows = "nixpkgs";

    ak-core.url = "github:aakropotkin/ak-core";
    ak-core.inputs.nixpkgs.follows = "nixpkgs";

    ini2json.url = "github:aakropotkin/ini2json";
    ini2json.inputs.nixpkgs.follows = "nixpkgs";

    slibtool.url = "github:aakropotkin/slibtool/nix";
    slibtool.inputs.nixpkgs.follows = "nixpkgs";

    sfm.url = "github:aakropotkin/sfm/nix";
    sfm.inputs.nixpkgs.follows = "nixpkgs";

    utils.url = "github:numtide/flake-utils/master";
    utils.inputs.nixpkgs.follows = "nixpkgs";
  };


/* -------------------------------------------------------------------------- */

  outputs =
    { self
    , nixpkgs
    , set_wm_class
    , ak-core
    , ini2json
    , slibtool
    , sfm
    , utils
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      mergeSets = sets:
        builtins.foldl' ( xs: x: nixpkgs.lib.recursiveUpdate xs x ) {} sets;
      systemsMap = utils.lib.eachSystemMap supportedSystems;

      # An extension to `nixpkgs.lib'
      lib = import ./lib {
        flake-utils = utils;
        nixpkgs-lib = nixpkgs.lib;
      };

    in {

/* -------------------------------------------------------------------------- */

      # Not effected by systems:
      inherit lib;
      repl = lib.librepl;  # `nix-repl> :a ( builtins.getFlake "ak-core" ).repl'

      # Wrappers for Pandoc, Makeinfo, and NixOS module options' generators.
      docgen = system: import ./pkgs/docgen {
        inherit (nixpkgs.legacyPackages.${system}) pandoc texinfo;
      };


/* -------------------------------------------------------------------------- */

      packages =
        let
          selfPkgs = systemsMap ( system:
            let pkgsFor = nixpkgs.legacyPackages.${system};
            in import ./pkgs {
              inherit nixpkgs system;
              inherit (nixpkgs) lib;
              inherit (pkgsFor) callPackage makeSetupHook writeShellScriptBin;
              inherit (pkgsFor) pandoc texinfo;
              pkgs = pkgsFor;
            } );
          inPkgs = systemsMap ( system:
            let ins = [set_wm_class ak-core ini2json sfm slibtool];
            in mergeSets ( map ( i: i.packages.${system} or {} ) ins ) );
        in mergeSets [selfPkgs inPkgs];

/* -------------------------------------------------------------------------- */

      overlays.set_wm_class = set_wm_class.overlay;
      overlays.ak-core = ak-core.overlays.default;
      overlays.ini2json = ini2json.overlay;
      overlays.slibtool = slibtool.overlay;
      overlays.sfm = sfm.overlay;
      overlays.default = self.overlays.ak-nix;
      # Merge input overlays in isolation from one another.
      overlays.ak-nix = final: prev:
        let
          pass = f: _: f;
          getOverlay = i: i.overlays.default or i.overlay or pass;
          overlayIsolated = i: ( getOverlay i ) final prev;
          ins = [set_wm_class ak-core ini2json sfm slibtool];
        in mergeSets ( map overlayIsolated ins );


/* -------------------------------------------------------------------------- */

      nixosModules.set_wm_class = set_wm_class.nixosModule;
      nixosModules.ini2json = ini2json.nixosModule;
      nixosModules.slibtool = slibtool.nixosModule;
      nixosModules.sfm = sfm.nixosModule;
      nixosModules.default = self.nixosModules.ak-nix;
      nixosModules.ak-nix = { pkgs, ... }@args:
        let
          pass = _: {};
          getModule = i: i.nixosModules.default or i.nixosModule or pass;
          ins = [set_wm_class ak-core ini2json sfm slibtool];
        in mergeSets ( map getModule ins );
      nixosModule = self.nixosModules.ak-nix;


/* -------------------------------------------------------------------------- */

      templates = {
        basic = {
          path = ./templates/basic;
          description = "a basic GNU build system package";
        };
        autotools = {
          path = ./templates/autotools;
          description = "a basic autotools project";
        };
        default = self.templates.basic;
      };


/* -------------------------------------------------------------------------- */

    };
}
