{

  description = "Misc Nix derivations and expressions";

  inputs.utils.url = "github:numtide/flake-utils/master";
  inputs.utils.inputs.nixpkgs.follows = "/nixpkgs";
  inputs.gitignore.url = "github:hercules-ci/gitignore.nix/master";
  inputs.gitignore.inputs.nixpkgs.follows = "/nixpkgs";
  inputs.nix.url = "github:NixOS/nix";
  inputs.nix.inputs.nixpkgs.follows = "/nixpkgs";


/* -------------------------------------------------------------------------- */

  outputs = { self, nixpkgs, utils, gitignore, nix, ... }: let

    inherit (utils.lib) eachDefaultSystemMap;

    # An extension to `nixpkgs.lib'.
    lib = import ./lib { inherit utils gitignore nix; inherit (nixpkgs) lib; };

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
        inherit system lib;
        inherit (nixpkgs.legacyPackages.${system})
          gzip gnutar coreutils bash findutils;
      } ) ) // { __functor = _self: system: _self.${system}; };


/* -------------------------------------------------------------------------- */

    linkutils = ( eachDefaultSystemMap ( system:
      import ./pkgs/build-support/trivial/link.nix {
        inherit system lib;
        inherit (nixpkgs.legacyPackages.${system}) coreutils bash;
      } ) ) // { __functor = _self: system: _self.${system}; };


/* -------------------------------------------------------------------------- */

    copyutils = ( eachDefaultSystemMap ( system:
      import ./pkgs/build-support/trivial/copy.nix {
        inherit system lib;
        inherit (nixpkgs.legacyPackages.${system}) coreutils bash;
      } ) ) // { __functor = _self: system: _self.${system}; };


/* -------------------------------------------------------------------------- */

    trivial = ( eachDefaultSystemMap ( system:
      self.tarutils.${system} // self.linkutils.${system} //
      self.copyutils.${system}
    ) ) // { __functor = _self: system: _self.${system}; };


/* -------------------------------------------------------------------------- */

    #packages = eachDefaultSystemMap ( system: {} );


/* -------------------------------------------------------------------------- */

    # Merge input overlays in isolation from one another.
    overlays.ak-nix = final: prev: let
      tarutils  = final.callPackages ./pkgs/build-support/trivial/tar.nix {};
      linkutils = final.callPackages ./pkgs/build-support/trivial/link.nix {};
      copyutils = final.callPackages ./pkgs/build-support/trivial/copy.nix {};
      trivial   = tarutils // linkutils // copyutils;
    in {
      lib = import ./lib { inherit (prev) lib; inherit utils nix; };
    } // trivial;
    overlays.default = self.overlays.ak-nix;


/* -------------------------------------------------------------------------- */

    nixosModules.ak-nix  = { config, ... }: {
      overlays = [self.overlays.ak-nix];
    };
    nixosModules.default = self.nixosModules.ak-nix;


/* -------------------------------------------------------------------------- */

    # FIXME: these blow up on `aarch64-darwin' for some reason; there's an issue
    # with how `system' is being passed to the test suite.
    #checks = eachDefaultSystemMap ( system: let
    #  pkgsFor = nixpkgs.legacyPackages.${system};
    #in {
    #  trivial = import ./pkgs/build-support/trivial/tests {
    #    inherit lib system nixpkgs;
    #    inherit (pkgsFor)
    #      writeText runCommandNoCC
    #      gnutar gzip coreutils findutils bash
    #    ;
    #    tarutils  = self.tarutils.${system};
    #    linkutils = self.linkutils.${system};

    #    outputAttr = "writeRunReport";
    #    # See additional configurable options in the `default.nix' file.
    #    # We didn't export them here, but if you're modifying this codebase
    #    # they may be useful to you.
    #  };
    #  default = self.checks.${system}.trivial;
    #} );


/* -------------------------------------------------------------------------- */

    templates = {
      default = self.templates.basic;
      basic.path = ./templates/basic;
      basic.description = "a basic GNU build system package";

      autotools.path = ./templates/autotools;
      autotools.description = "a basic autotools project";

      # FIXME:
      # update this template with some of the improvements made
      # to `./pkgs/build-support/trivial/tests/'.
      tests.path = ./templates/tests;
      tests.description = "a test harness for Nix expressions and drvs";
    };


/* -------------------------------------------------------------------------- */

  };
}
