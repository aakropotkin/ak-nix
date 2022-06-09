{
  description = "a small utility to create JSON objects";

  inputs.utils.url = "github:numtide/flake-utils";
  inputs.utils.inputs.nixpkgs.follows = "/nixpkgs";
  inputs."".follows = "/";

  inputs.jo-src = {
    url = "github:jpmens/jo/1.6";
    flake = false;
  };

  outputs = { self, nixpkgs, utils, jo-src }: {
    packages = utils.lib.eachDefaultSystemMap ( system: {
      jo = nixpkgs.legacyPackages.${system}.callPackage ./. {
        inherit jo-src;
      };
      default = self.packages.${system}.jo;
    } );

    overlays.jo = final: prev: {
      jo = prev.callPackage ./. { inherit jo-src; };
    };
    overlays.default = self.overlays.jo;

    nixosModules.jo  = { config, ... }: { overlays = [self.overlays.jo]; };
    nixosModules.default = self.nixosModules.jo;

    checks = utils.lib.eachDefaultSystemMap ( system: import ./checks.nix {
      inherit (self.packages.${system}) jo;
      inherit (nixpkgs.legacyPackages.${system}) runCommandNoCC diffutils;
    } );

  };
}
