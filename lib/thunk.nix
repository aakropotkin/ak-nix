# ============================================================================ #
#
# Essentially extensions and renames of Nixpkgs' `lib/customization.nix'.
# Largely this aims to use more "user friendly" names to make the use of
# things like `callPackageWith' and ``
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  # It's `makeOverridable' except you can customize the names.
  mkThunkWithName = {
    override           ? "__override"
  , overrideDerivation ? "__overrideDrv"
  }: autoArgs: fn: args: let
  in null;


# ---------------------------------------------------------------------------- #

in {

}


# ---------------------------------------------------------------------------- #
#
#
# ============================================================================ #
