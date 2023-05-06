# ============================================================================ #
#
#
# ---------------------------------------------------------------------------- #

{

# ---------------------------------------------------------------------------- #

  description = "a small utility to create JSON objects";

# ---------------------------------------------------------------------------- #

  inputs.jo-src.url = "github:jpmens/jo/1.6";
  inputs.jo-src.flake = false;

# ---------------------------------------------------------------------------- #

  outputs = { self, nixpkgs, utils, jo-src, ... }: let

# ---------------------------------------------------------------------------- #

    eachDefaultSystemMap = fn: let
      defaultSystems = [
        "x86_64-linux"  "aarch64-linux"  "i686-linux"
        "x86_64-darwin" "aarch64-darwin"
      ];
      proc = system: { name = system; value = fn system; };
    in builtins.listToAttrs ( map proc defaultSystems );


# ---------------------------------------------------------------------------- #

    overlays.jo = final: prev: {
      jo = prev.callPackage ./. { inherit jo-src; };
    };
    overlays.default = overlays.jo;


# ---------------------------------------------------------------------------- #

    packages = eachDefaultSystemMap ( system: let
      jo = nixpkgs.legacyPackages.${system}.callPackage ./. { inherit jo-src; };
    in { inherit jo; default = jo; } );


# ---------------------------------------------------------------------------- #

  in {

# ---------------------------------------------------------------------------- #

    inherit overlays packages;

# ---------------------------------------------------------------------------- #

    nixosModules.jo  = { config, ... }: { overlays = [overlays.jo]; };
    nixosModules.default = self.nixosModules.jo;

    checks = utils.lib.eachDefaultSystemMap ( system: import ./checks.nix {
      inherit (packages.${system}) jo;
      inherit (nixpkgs.legacyPackages.${system}) runCommandNoCC diffutils;
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
