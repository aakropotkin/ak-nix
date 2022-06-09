{

  description = "Misc Nix derivations and expressions";

  inputs.utils.url = "github:numtide/flake-utils/master";
  inputs.utils.inputs.nixpkgs.follows = "/nixpkgs";

  inputs.jo.url = "path:./pkgs/development/tools/jo";
  inputs.jo.inputs.utils.follows = "/utils";
  inputs.jo.inputs.nixpkgs.follows = "/nixpkgs";
  inputs.jo.follows = "";


/* -------------------------------------------------------------------------- */

  outputs = { self, nixpkgs, utils, jo }: let

    inherit (utils.lib) eachDefaultSystemMap;

    # An extension to `nixpkgs.lib'.
    lib = import ./lib { inherit utils; inherit (nixpkgs) lib; };

  in {

/* -------------------------------------------------------------------------- */

      # Not effected by systems:
      inherit lib;
      repl = lib.librepl;  # `nix-repl> :a ( builtins.getFlake "ak-core" ).repl'

      # Wrappers for Pandoc, Makeinfo, and NixOS module options' generators.
      docgen = ( eachDefaultSystemMap ( system: import ./pkgs/docgen {
        inherit (nixpkgs.legacyPackages.${system}) pandoc texinfo;
      } ) ) // { __functor = _self: system: _self.${system}; };


/* -------------------------------------------------------------------------- */

      tarutils = ( eachDefaultSystemMap ( system:
        import ./pkgs/build-support/trivial/tar.nix {
          inherit system;
          inherit (nixpkgs.legacyPackages.${system}) gzip gnutar;
        } ) ) // { __functor = _self: system: _self.${system}; };


/* -------------------------------------------------------------------------- */

      linkutils = ( eachDefaultSystemMap ( system:
        import ./pkgs/build-support/trivial/link.nix {
          inherit system lib;
          inherit (nixpkgs.legacyPackages.${system}) coreutils bash;
        } ) ) // { __functor = _self: system: _self.${system}; };


/* -------------------------------------------------------------------------- */

      trivial = ( eachDefaultSystemMap ( system:
          self.tarutils.${system} // self.linkutils.${system}
        ) ) // { __functor = _self: system: _self.${system}; };


/* -------------------------------------------------------------------------- */

      packages = eachDefaultSystemMap ( system: {
        inherit (jo.packages.${system}) jo;
      } );

/* -------------------------------------------------------------------------- */

      # Merge input overlays in isolation from one another.
      overlays.ak-nix = final: prev: {
        lib = import ./lib { inherit (prev) lib; inherit utils; };
      };
      overlays.default = self.overlays.ak-nix;
      overlays.jo = jo.overlays.jo;


/* -------------------------------------------------------------------------- */

      nixosModules.ak-nix  = { config, ... }: {
        overlays = [self.overlays.ak-nix];
      };
      nixosModules.default = self.nixosModules.ak-nix;
      nixosModules.jo = jo.nixosModules.jo;


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

      checks = eachDefaultSystemMap ( system: jo.checks.${system} );

/* -------------------------------------------------------------------------- */

    };
}
