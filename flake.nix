{

  description = "Misc Nix derivations and expressions";

  inputs.nix.url = "github:NixOS/nix";
  inputs.nix.inputs.nixpkgs.follows = "/nixpkgs";

  inputs.yants-src = {
    url = "git+https://code.tvl.fyi/depot.git:/nix/yants.git";
    flake = false;
  };


# ---------------------------------------------------------------------------- #

  outputs = { self, nixpkgs, nix, yants-src, ... }: let

    # An extension to `nixpkgs.lib'.
    lib = import ./lib { inherit nix yants-src; inherit (nixpkgs) lib; };

    inherit (lib) eachDefaultSystemMap;

  in {

# ---------------------------------------------------------------------------- #

    # Not effected by systems:
    inherit lib;

    # `nix-repl> :a ( builtins.getFlake "ak-core" ).repl'
    repl = let
      pkgsFor = nixpkgs.legacyPackages.${builtins.currentSystem};
    in lib.joinAttrs [
      ( lib.extend ( _: _: { inNixRepl = true; } ) )
      lib.librepl
      builtins
      {
        flake-registry = let
          # FIXME: use "import if exists"
          ureg = lib.importJSON
                   "${builtins.getEnv "HOME"}/.config/nix/registry.json";
          nv = { from, to, ... }: {
            # FIXME: any `from.ref' will bite you
            name = from.id;
            value = to;
          };
        in builtins.listToAttrs ( map nv ureg.flakes );
        inherit pkgsFor;
        np = pkgsFor;
      }
    ];

    # Wrappers for Pandoc, Makeinfo, and NixOS module options' generators.
    docgen = ( eachDefaultSystemMap ( system: import ./pkgs/docgen {
      inherit (nixpkgs.legacyPackages.${system}) pandoc texinfo;
    } ) ) // { __functor = _self: system: _self.${system}; };


# ---------------------------------------------------------------------------- #

    tarutils = ( eachDefaultSystemMap ( system:
      import ./pkgs/build-support/trivial/tar.nix {
        inherit system lib;
        inherit (nixpkgs.legacyPackages.${system})
          gzip gnutar coreutils bash findutils;
      } ) ) // { __functor = _self: system: _self.${system}; };


# ---------------------------------------------------------------------------- #

    linkutils = ( eachDefaultSystemMap ( system:
      import ./pkgs/build-support/trivial/link.nix {
        inherit system lib;
        inherit (nixpkgs.legacyPackages.${system}) coreutils bash;
      } ) ) // { __functor = _self: system: _self.${system}; };


# ---------------------------------------------------------------------------- #

    copyutils = ( eachDefaultSystemMap ( system:
      import ./pkgs/build-support/trivial/copy.nix {
        inherit system lib;
        inherit (nixpkgs.legacyPackages.${system}) coreutils bash;
      } ) ) // { __functor = _self: system: _self.${system}; };


# ---------------------------------------------------------------------------- #

    trivial = ( eachDefaultSystemMap ( system:
      self.tarutils.${system} // self.linkutils.${system} //
      self.copyutils.${system}
    ) ) // { __functor = _self: system: _self.${system}; };


# ---------------------------------------------------------------------------- #

    packages = eachDefaultSystemMap ( system: let
      pkgsFor = self.legacyPackages.${system};
    in {
      tests = ( pkgsFor.callPackage ./tests {
        inherit pkgsFor lib nixpkgs system;
      } ).checkDrv;
    } );


# ---------------------------------------------------------------------------- #

    # Merge input overlays in isolation from one another.
    overlays.ak-nix = final: prev: let
      tarutils = import ./pkgs/build-support/trivial/tar.nix {
        inherit (prev) lib gzip gnutar coreutils bash findutils system;
      };
      linkutils = import ./pkgs/build-support/trivial/link.nix {
        inherit (prev) lib coreutils bash system;
      };
      copyutils = import ./pkgs/build-support/trivial/copy.nix {
        inherit (prev) lib coreutils bash system;
      };
      trivial = tarutils // linkutils // copyutils;
    in {
      lib = import ./lib { inherit (prev) lib; inherit nix yants-src; };
    } // trivial;
    overlays.default = self.overlays.ak-nix;

    overlays.ytypes = final: prev: lib.ytypes // prev;


# ---------------------------------------------------------------------------- #

  legacyPackages = eachDefaultSystemMap ( system:
    nixpkgs.legacyPackages.${system}.extend self.overlays.ak-nix
  );


# ---------------------------------------------------------------------------- #

    nixosModules.ak-nix  = { config, ... }: {
      overlays = [self.overlays.ak-nix];
    };
    nixosModules.default = self.nixosModules.ak-nix;


# ---------------------------------------------------------------------------- #

    templates = {
      default = self.templates.basic;

      basic.path = ./templates/basic;
      basic.description = "a dank starter flake";

      meaty.path = ./templates/meaty;
      meaty.description = "a meaty starter flake";

      basic-pkg.path = ./templates/basic-pkg;
      basic-pkg.description = "a basic GNU build system package";

      autotools.path = ./templates/autotools;
      autotools.description = "a basic autotools project";

      lib-sub.path = ./templates/lib-sub;
      lib-sub.description = "a sub library file";

      tests.path = ./templates/tests;
      tests.description = "a test harness for Nix expressions and drvs";

      tests-sub.path = ./templates/tests-sub;
      tests-sub.description = "a subset of tests for the `ak-nix' Test harness";
    };


# ---------------------------------------------------------------------------- #

  };
}
