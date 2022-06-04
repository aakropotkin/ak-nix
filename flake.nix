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
    ak-core.url      = "github:aakropotkin/ak-core";
    ini2json.url     = "github:aakropotkin/ini2json";
    slibtool.url     = "github:aakropotkin/slibtool/nix";
    sfm.url          = "github:aakropotkin/sfm/nix";
    utils.url        = "github:numtide/flake-utils/master";
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
      pkgsFor = import nixpkgs { system = "x86_64-linux"; };
      mergeSets = { lib ? pkgsFor.lib }: sets:
        builtins.foldl' ( xs: x: lib.recursiveUpdate xs x ) {} sets;
    in {

      # An extension to `nixpkgs.lib'
      lib = import ./lib {
        flake-utils = utils;
        nixpkgs-lib = nixpkgs.lib;
      };


/* -------------------------------------------------------------------------- */

      docgen =
        let forSys = { system }:
              let pkgsFor = import nixpkgs { inherit system; }; in
              import ./pkgs/docgen { inherit (pkgsFor) pandoc texinfo; };
            inherit (builtins) attrsToList;
            supportedSystems =
              ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
        in attrsToList ( map forSys supportedSystems );


/* -------------------------------------------------------------------------- */

      packages.x86_64-linux = mergeSets {} [
          set_wm_class.packages.x86_64-linux
          ak-core.packages.x86_64-linux     
          ini2json.packages.x86_64-linux    
          sfm.packages.x86_64-linux         
          slibtool.packages.x86_64-linux    
          ( import ./pkgs {
              inherit (pkgsFor) lib callPackage makeSetupHook;
              inherit (pkgsFor) writeShellScriptBin;
            } )
        ];


/* -------------------------------------------------------------------------- */

      overlays.set_wm_class = set_wm_class.overlay;
      overlays.ak-core = ak-core.overlays.default;
      overlays.ini2json = ini2json.overlay;
      overlays.slibtool = slibtool.overlay;
      overlays.sfm = sfm.overlay;
      overlays.ak-nix = final: prev: mergeSets {} [
        ( set_wm_class.overlay final prev )    
        ( ak-core.overlays.default final prev )
        ( ini2json.overlay final prev )        
        ( sfm.overlay final prev )             
        ( slibtool.overlay final prev )
      ];
      overlays.default = self.overlays.ak-nix;


/* -------------------------------------------------------------------------- */

      nixosModules.set_wm_class = set_wm_class.nixosModule;
      #nixosModules.ak-core = ak-core.nixosModule;
      nixosModules.ini2json = ini2json.nixosModule;
      nixosModules.slibtool = slibtool.nixosModule;
      nixosModules.sfm = sfm.nixosModule;
      nixosModules.ak-nix = { pkgs, ... }@args: mergeSets {} [
        ( set_wm_class.nixosModule args )
        ( ak-core.nixosModule args )     
        ( ini2json.nixosModule args )    
        ( sfm.nixosModule args )         
        ( slibtool.nixosModule args )
      ];
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
