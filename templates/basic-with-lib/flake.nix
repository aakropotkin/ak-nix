# ============================================================================ #
#
# A dank flake starter kit.
#
# ---------------------------------------------------------------------------- #

{

# ---------------------------------------------------------------------------- #

  description = "A dank starter flake";

# ---------------------------------------------------------------------------- #

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";
  inputs.ak-nix.url  = "github:aakropotkin/ak-nix/main";
  inputs.ak-nix.inputs.nixpkgs.follows = "/nixpkgs";

# ---------------------------------------------------------------------------- #

  outputs = { self, nixpkgs, ak-nix, ... }: let

# ---------------------------------------------------------------------------- #

    eachDefaultSystemMap = fn: let
      defaultSystems = [
        "x86_64-linux"  "aarch64-linux"  "i686-linux"
        "x86_64-darwin" "aarch64-darwin"
      ];
      proc = system: { name = system; value = fn system; };
    in builtins.listToAttrs ( map proc defaultSystems );


# ---------------------------------------------------------------------------- #

    lib        = ak-nix.lib.extend self.overlays.lib;
    pkgsForSys = system: nixpkgs.legacyPackages.${system};

# ---------------------------------------------------------------------------- #

  in {

# ---------------------------------------------------------------------------- #

    # Pure `lib' extensions.
    overlays.lib  = final: prev: {};
    # Nixpkgs overlay: Builders, Packages, Overrides, etc.
    overlays.pkgs = final: prev: let
      callPackagesWith = auto: prev.lib.callPackagesWith ( final // auto );
      callPackageWith  = auto: prev.lib.callPackageWith ( final // auto );
      callPackages     = callPackagesWith {};
      callPackage      = callPackageWith {};
    in {
      lib = prev.lib.extend self.overlays.lib;
    };
    # Recommended: Compose with deps into a single overlay.
    overlays.default = self.overlays.pkgs;


# ---------------------------------------------------------------------------- #

    # Installable Packages for Flake CLI.
    packages = eachDefaultSystemMap ( system: let
      pkgsFor = pkgsForSys system;
    in {} );


# ---------------------------------------------------------------------------- #

  };  # End `outputs'
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
