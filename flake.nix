{
  description = "A collection of aakropotkin's nix flakes";

  inputs.nixpkgs.follows = "nix/nixpkgs";
  inputs.set_wm_class.url = "github:aakropotkin/set_wm_class";
  inputs.ak-core.url = "github:aakropotkin/ak-core";
  inputs.ini2json.url = "github:aakropotkin/ini2json";
  inputs.slibtool.url = "github:aakropotkin/slibtool";

  outputs =
    { self, nixpkgs, nix,
      set_wm_class, ak-core, ini2json, slibtool,
      ...
    }: {
      packages.x86_64-linux =
        set_wm_class.packages.x86_64-linux //
        ak-core.packages.x86_64-linux      //
        ini2json.packages.x86_64-linux     //
        slibtool.packages.x86_64-linux;

      overlays.set_wm_class = set_wm_class.overlay;
      overlays.ak-core = ak-core.overlay;
      overlays.ini2json = ini2json.overlay;
      overlays.slibtool = slibtool.overlay;
      overlays.ak-nix = final: prev:
        ( set_wm_class.overlay final prev ) //
        ( ak-core.overlay final prev )      //
        ( ini2json.overlay final prev )     //
        ( slibtool.overlay final prev );
      overlay = self.overlays.ak-nix;

      nixosModules.set_wm_class = set_wm_class.nixosModule;
      nixosModules.ak-core = ak-core.nixosModule;
      nixosModules.ini2json = ini2json.nixosModule;
      nixosModules.slibtool = slibtool.nixosModule;
      nixosModules.ak-nix = { pkgs, ... }@args:
        ( set_wm_class.nixosModule args ) //
        ( ak-core.nixosModule args )      //
        ( ini2json.nixosModule args )     //
        ( slibtool.nixosModules args );
      nixosModule = self.nixosModules.ak-nix; 

    };
}
