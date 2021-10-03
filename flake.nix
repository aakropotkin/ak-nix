{
  description = "A very basic flake";

  inputs.nixpkgs.follows = "nix/nixpkgs";
  inputs.set_wm_class.url = "github:aakropotkin/set_wm_class";
  inputs.ak-core.url = "github:aakropotkin/ak-core";

  outputs = { self, nixpkgs, set_wm_class, ak-core, nix, ... }: {

    packages.x86_64-linux =
      set_wm_class.packages.x86_64-linux //
      ak-core.packages.x86_64-linux;

    overlays.set_wm_class = set_wm_class.overlay;
    overlays.ak-core = ak-core.overlay;
    overlays.ak-nix = final: prev:
      ( set_wm_class.overlay final prev ) //
      ( ak-core.overlay final prev );
    overlay = self.overlays.ak-nix;

    nixosModules.set_wm_class = set_wm_class.nixosModule;
    nixosModules.ak-core = ak-core.nixosModule;
    nixosModules.ak-nix = { pkgs, ... }@args:
      ( set_wm_class.nixosModule args ) //
      ( ak-core.nixosModule args );
    nixosModule = self.nixosModules.ak-nix; 

  };
}
