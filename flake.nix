# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{

  description = "Misc Nix derivations and expressions";

# ---------------------------------------------------------------------------- #

  outputs = { nixpkgs, ... }: let

# ---------------------------------------------------------------------------- #

    # A standalone lib overlay, useful if you are creating other pure libs.
    libOverlays.default = import ./lib/overlay.lib.nix;

    # Extends Nixpkgs with new builders as well as our lib and type extensions.
    # Types are stashed under `lib.ytypes'.
    overlays.default = final: prev: let
      tarutils = import ./pkgs/build-support/trivial/tar.nix {
        inherit (prev) gzip gnutar coreutils bash findutils system;
        inherit (final) lib;
      };
      linkutils = import ./pkgs/build-support/trivial/link.nix {
        inherit (prev) coreutils bash system;
        inherit (final) lib;
      };
      copyutils = import ./pkgs/build-support/trivial/copy.nix {
        inherit (prev) coreutils bash system;
        inherit (final) lib;
      };
      trivial = tarutils // linkutils // copyutils;
    in {
      lib = prev.lib.extend libOverlays.default;
    } // trivial;

    # These are already included in our lib overlay.
    # We splice them out here to help simplify the use of overrides in other
    # flakes with complex compositions.
    # Users should ignore this overlay - you shouldn't ever need to this overlay
    # unless you're trying to stub the type checkers with dummy functions.
    ytOverlays.default  = final: prev:
      ( nixpkgs.lib.extend libOverlays.default ).ytypes;

# ---------------------------------------------------------------------------- #

    nixosModules.default = { config, ... }: { overlays = [overlays.ak-nix]; };

# ---------------------------------------------------------------------------- #

    inherit (nixpkgs.lib.extend libOverlays.default) eachDefaultSystemMap;

    lib = nixpkgs.lib.extend libOverlays.default;

# ---------------------------------------------------------------------------- #

    packages = eachDefaultSystemMap ( system: let
      pkgsFor = nixpkgs.legacyPackages.${system}.extend overlays.default;
    in {
      tests = ( pkgsFor.callPackage ./tests {
        inherit pkgsFor nixpkgs system;
        inherit (pkgsFor) lib;
      } ).checkDrv;
    } );


# ---------------------------------------------------------------------------- #

  in {

# ---------------------------------------------------------------------------- #

    # Inheriting these allows us to avoid referring to a "global self".
    # This is important in order to avoid quirks in lockfiles, and to simplify
    # the use of `callFlake'.
    inherit overlays libOverlays ytOverlays nixosModules lib packages;

# ---------------------------------------------------------------------------- #

    # `nix-repl> :a ( builtins.getFlake "ak-core" ).repl'
    repl = let
      pkgsFor = nixpkgs.legacyPackages.${builtins.currentSystem}.extend
                  overlays.default;
      lib = let
        pureLib = nixpkgs.lib.extend libOverlays.default;
      in pureLib.extend ( _: _: { inNixRepl = true; } );
    in lib.joinAttrs [
      lib
      lib.librepl
      builtins
      { inherit pkgsFor lib; }
    ];

    # Wrappers for Pandoc, Makeinfo, and NixOS module options' generators.
    docgen = ( eachDefaultSystemMap ( system: import ./pkgs/docgen {
      inherit (nixpkgs.legacyPackages.${system}) pandoc texinfo;
    } ) ) // { __functor = _self: system: _self.${system}; };


# ---------------------------------------------------------------------------- #

    checks = lib.eachDefaultSystemMap ( system: let
      pkgsFor = nixpkgs.legacyPackages.${system}.extend overlays.default;
    in {
      inherit (packages.${system}) tests;
      untarSanPerms = ( pkgsFor.callPackage ./tests/tar.nix {
        inherit pkgsFor;
      } ).drvs.testUntarSanPerms_0;
    } );


# ---------------------------------------------------------------------------- #

    legacyPackages = eachDefaultSystemMap ( system:
      nixpkgs.legacyPackages.${system}.extend overlays.default
    );


# ---------------------------------------------------------------------------- #

    templates = let
      basic.path = ./templates/basic;
      basic.description = "a dank starter flake";
    in {
      inherit basic;
      default = basic;

      meaty.path        = ./templates/meaty;
      meaty.description = "a meaty starter flake";

      basic-pkg.path        = ./templates/basic-pkg;
      basic-pkg.description = "a basic GNU build system package";

      autotools.path        = ./templates/autotools;
      autotools.description = "a basic autotools project";

      lib-sub.path        = ./templates/lib-sub;
      lib-sub.description = "a sub library file";

      tests.path        = ./templates/tests;
      tests.description = "a test harness for Nix expressions and drvs";

      tests-sub.path        = ./templates/tests-sub;
      tests-sub.description = "a subset of tests for the `ak-nix' Test harness";

      nix-plugin.path        = ./templates/nix-plugin;
      nix-plugin.description = "a nix plugin with wrapper executable";
    };


# ---------------------------------------------------------------------------- #

  };  # End Outputs

# ---------------------------------------------------------------------------- #

}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
