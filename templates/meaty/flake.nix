# ============================================================================ #
#
# A meaty flake starter flake.
#
# FIXME: You need to edit "NAME" stubs in this file, and delete the time-bomb
# `ASSERT_SETUP' once you've set up this flake.
# Search around for any "FIXME" messages.
#
# ---------------------------------------------------------------------------- #

{
  description = "A meaty starter flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";
  inputs.ak-nix.url  = "github:aakropotkin/ak-nix/main";
  inputs.ak-nix.inputs.nixpkgs.follows = "/nixpkgs";

# ---------------------------------------------------------------------------- #

  outputs = { nixpkgs, ak-nix, ... }: let

# ---------------------------------------------------------------------------- #

    # Pure `lib' extensions.
    libOverlays.NAME = final: prev: let
      callLibWith = { lib ? final, ... } @ auto: x: let
        f    = if prev.lib.isFunction x then x else import x;
        args = builtins.intersectAttrs ( builtins.functionArgs f )
                                       ( { inherit lib; } // auto );
      in f args;
      callLibsWith = auto:
        builtins.foldl' ( acc: x: acc // ( callLibWith auto x ) ) {};
      callLib  = callLibWith {};
      callLibs = callLibsWith {};
    in {
      # FIXME: put lib extensions here.

      # Import a file as a named sub-lib.
      # libfoo = callLib  ./lib/foo.nix;

      # Join multiple files into a single named sub-lib.
      # libbar = callLibs [./lib/bar-a.nix ./lib/bar-b.nix];

      # Write an inline definition of a sub-lib.
      libNAME = {
        greet = name:
          builtins.trace "\nHowdy ${name}!\n" null;
      };

      # Add a new top-level function.
      phony = let
        die = throw "FIXME: You should delete these stub functions";
      in builtins.deepSeq die null;

      # Add a function from a sub-lib to the top level.
      inherit (final.libNAME) greet;
    };  # End `libNAME' Overlay.

    # Any other `lib' overlays we depend on.
    libOverlays.deps = ak-nix.libOverlays.default;
    # Our overlay + our deps.
    libOverlays.default = nixpkgs.lib.composeExtensions libOverlays.deps
                                                        libOverlays.NAME;

    # NOTE: Consume as `lib = nixpkgs.lib.extend NAME.libOverlays.default'.
    # Assuming the pattern of `libOverlays.{deps,NAME,default}' is followed
    # across your dependencies, you can compose arbitrary combinations of
    # direct dependencies' `libOverlays.default' extensions without worrying
    # about transitive dependencies' extensions.


# ---------------------------------------------------------------------------- #

    overlays.deps = ak-nix.overlays.default;
    # Reccomended for multiple input overlays:
    #   lib.composeManyExtensions [ak-nix.overlays.default ...];

    # Nixpkgs overlay: Builders, Packages, Overrides, etc.
    overlays.NAME = final: prev: let
      callPackagesWith = auto: prev.lib.callPackagesWith ( final // auto );
      callPackageWith  = auto: prev.lib.callPackageWith ( final // auto );
      callPackages     = callPackagesWith {};
      callPackage      = callPackageWith {};
    in {
      lib = prev.lib.extend libOverlays.default;
      # FIXME: Put real package definitions here.
      howdy = prev.writeShellScriptBin "howdy" ''echo "Howdy!";'';
    };

    # By default, compose with our deps into a single overlay.
    # NOTE: Same rationale as described for `libOverlays'.
    overlays.default = nixpkgs.lib.composeExtensions overlays.deps
                                                     overlays.NAME;

    # Nixpkgs + ak-nix + our extensions.
    # NOTE: You could expose this publicly as `legacyPackages.${system}', just
    # keep in mind that `nix flake check' may run a large number of audits.
    pkgsForSys = system:
      nixpkgs.legacyPackages.${system}.extend overlays.default;

# ---------------------------------------------------------------------------- #

    # FIXME: Pick your poison:
    #supportedSystems = [
    #  "x86_64-linux"  "aarch64-linux"
    #  "x86_64-darwin" "aarch64-darwin"
    #];
    supportedSystems       = ak-nix.lib.defaultSystems;
    eachSupportedSystemMap = ak-nix.lib.eachSystemMap supportedSystems;


# ---------------------------------------------------------------------------- #

# FIXME: Remove this after setting up this template.

    ASSERT_SETUP = pkg: let
      # This prevents triggering the time bomb in upstream `ak-nix' checks.
      hasGitDir = builtins.pathExists "${toString ./.}/.git/.";
      msg = ''
        It looks like you need to setup your flake template!
        Read all the "FIXME" messages across the file, and then remove the
        `ASSERT_SETUP' time-bomb near the bottom when you're done.
      '';
    in if hasGitDir then builtins.deepSeq ( throw msg ) pkg else pkg;

# FIXME: Remove this after setting up this template.


# ---------------------------------------------------------------------------- #

  in {  # Begin Outputs

# ---------------------------------------------------------------------------- #

    # Nixpkgs + ak-nix + our extensions.
    lib = nixpkgs.lib.extend libOverlays.default;

# ---------------------------------------------------------------------------- #

    # Installable Packages for Flake CLI.
    packages = eachSupportedSystemMap ( system: let
      pkgsFor = pkgsForSys system;
    in {
      # FIXME: put real package definitions here.
      inherit (pkgsFor) howdy;
      ASSERT_SETUP_TIMEBOMB = ASSERT_SETUP pkgsFor.howdy;
    } );


# ---------------------------------------------------------------------------- #

  };  # End Outputs
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
