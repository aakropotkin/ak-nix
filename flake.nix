{
  description = "A collection of aakropotkin's nix flakes";
  inputs = {
    set_wm_class.url = github:aakropotkin/set_wm_class;
    ak-core.url      = github:aakropotkin/ak-core;
    ini2json.url     = github:aakropotkin/ini2json;
    slibtool.url     = github:aakropotkin/slibtool/nix;
    sfm.url          = github:aakropotkin/sfm/nix;
    utils.url        = github:numtide/flake-utils;
  };

  outputs =
    { self
    , nixpkgs
    , set_wm_class
    , ak-core
    , ini2json
    , slibtool
    , sfm
    , utils
    }: {
      lib = import ./lib { flake-utils = utils; };

      packages.x86_64-linux =
        set_wm_class.packages.x86_64-linux //
        ak-core.packages.x86_64-linux      //
        ini2json.packages.x86_64-linux     //
        sfm.packages.x86_64-linux          //
        slibtool.packages.x86_64-linux     //
        {
          shall = nixpkgs.legacyPackages.x86_64-linux.callPackage ./shall.nix {
            inherit (nixpkgs.legacyPackages.x86_64-linux)
              buildEnv bash tcsh zsh ksh dash;
          };
        } // ( nixpkgs.legacyPackages.x86_64-linux.callPackage ./pkgs {} );

      overlays.set_wm_class = set_wm_class.overlay;
      overlays.ak-core = ak-core.overlays.default;
      overlays.ini2json = ini2json.overlay;
      overlays.slibtool = slibtool.overlay;
      overlays.sfm = sfm.overlay;
      overlays.ak-nix = final: prev:
        ( set_wm_class.overlay final prev )      //
        ( ak-core.overlays.default final prev )  //
        ( ini2json.overlay final prev )          //
        ( sfm.overlay final prev )               //
        ( slibtool.overlay final prev );
      overlays.default = self.overlays.ak-nix;

      nixosModules.set_wm_class = set_wm_class.nixosModule;
      #nixosModules.ak-core = ak-core.nixosModule;
      nixosModules.ini2json = ini2json.nixosModule;
      nixosModules.slibtool = slibtool.nixosModule;
      nixosModules.sfm = sfm.nixosModule;
      nixosModules.ak-nix = { pkgs, ... }@args:
        ( set_wm_class.nixosModule args ) //
        ( ak-core.nixosModule args )      //
        ( ini2json.nixosModule args )     //
        ( sfm.nixosModule args )          //
        ( slibtool.nixosModule args );
      nixosModule = self.nixosModules.ak-nix; 

      templates.basic = {
        path = ./templates/basic;
        description = "a basic GNU build system package";
      };
      templates.default = self.templates.basic;

    }
}
