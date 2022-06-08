{

  description = "Misc Nix derivations and expressions";

  inputs.utils.url = "github:numtide/flake-utils/master";
  inputs.utils.inputs.nixpkgs.follows = "/nixpkgs";


/* -------------------------------------------------------------------------- */

  outputs = { self, nixpkgs, utils }: let

    inherit (utils.lib) eachDefaultSystemMap;

    # An extension to `nixpkgs.lib'.
    lib = import ./lib {
      inherit utils;
      nixpkgs-lib = nixpkgs.lib;
    };

  in {

/* -------------------------------------------------------------------------- */

      # Not effected by systems:
      inherit lib;
      repl = lib.librepl;  # `nix-repl> :a ( builtins.getFlake "ak-core" ).repl'

      # Wrappers for Pandoc, Makeinfo, and NixOS module options' generators.
      docgen = ( eachDefaultSystemMap ( system: import ./pkgs/docgen {
        inherit (nixpkgs.legacyPackages.${system}) pandoc texinfo;
      } ) ) // { __functor = docgenSelf: system: docgenSelf.${system}; };


/* -------------------------------------------------------------------------- */

      tarutils = ( eachDefaultSystemMap ( system:
        import ./pkgs/build-support/trivial/tar.nix {
          inherit system;
          inherit (nixpkgs.legacyPackages.${system}) gzip gnutar;
        } ) ) // { __functor = tarSelf: system: tarSelf.${system}; };


/* -------------------------------------------------------------------------- */

      packages = eachDefaultSystemMap ( system: import ./pkgs {
        inherit nixpkgs system lib;
        inherit (nixpkgs.legacyPackages.${system})
          callPackage makeSetupHook writeShellScriptBin texinfo pandoc
          gnutar gzip;
        pkgs = nixpkgs.legacyPackages.${system};
      } );

/* -------------------------------------------------------------------------- */

      # Merge input overlays in isolation from one another.
      overlays.ak-nix = final: prev: import ./pkgs {
        inherit nixpkgs;
        inherit (final)
          system lib callPackage makeSetupHook writeShellScriptBin pandoc
          texinfo gnutar gzip;
        pkgs = final;
      };
      overlays.default = self.overlays.ak-nix;


/* -------------------------------------------------------------------------- */

      nixosModules.ak-nix  = { config, ... }: {
        overlays = [self.overlays.ak-nix];
      };
      nixosModules.default = self.nixosModules.ak-nix;


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
