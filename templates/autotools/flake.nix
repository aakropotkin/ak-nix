# ============================================================================ #
#
#
# ---------------------------------------------------------------------------- #

{

# ---------------------------------------------------------------------------- #

  # FIXME: Replace "PROJECT" with your project name.
  description = "a basic autotools package";

# ---------------------------------------------------------------------------- #

  outputs = { self, nixpkgs, utils, PROJECT-src }: let

# ---------------------------------------------------------------------------- #

    eachDefaultSystemMap = fn: let
      defaultSystems = [
        "x86_64-linux"  "aarch64-linux"  "i686-linux"
        "x86_64-darwin" "aarch64-darwin"
      ];
      proc = system: { name = system; value = fn system; };
    in builtins.listToAttrs ( map proc defaultSystems );

# ---------------------------------------------------------------------------- #

  in {

    packages = eachDefaultSystemMap ( system: let
      pkgsFor = import nixpkgs { inherit system; };
      PROJECT = pkgsFor.callPackage ./default.nix {};
    in {
      inherit PROJECT;
      default = PROJECT;
    } );


# ---------------------------------------------------------------------------- #

  };  # End `outputs'


# ---------------------------------------------------------------------------- #

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
