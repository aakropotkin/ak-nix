# ============================================================================ #
#
# A meaty flake starter flake.
#
# ---------------------------------------------------------------------------- #

{
  description = "A meaty starter flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";
  inputs.ak-nix.url  = "github:aakropotkin/ak-nix/main";
  inputs.ak-nix.inputs.nixpkgs.follows = "/nixpkgs";

# ---------------------------------------------------------------------------- #

  outputs = { self, nixpkgs, ak-nix, ... }: let

    # Nixpkgs + ak-nix + our extensions.
    lib = ak-nix.lib.extend self.overlays.lib;

    # Nixpkgs + ak-nix + our extensions.
    pkgsForSys = system:
      nixpkgs.legacyPackages.${system}.extend self.overlays.default;

    # FIXME: Pick your poison:
    #supportedSystems = [
    #  "x86_64-linux"  "aarch64-linux"
    #  "x86_64-darwin" "aarch64-darwin"
    #];
    supportedSystems = lib.defaultSystems;
    eachSupportedSystemMap = lib.eachSystemMap supportedSystems;

  in {  # Begin Outputs

# ---------------------------------------------------------------------------- #

    # Pure `lib' extensions.
    overlays.lib  = final: prev: let
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
      # libfoo = callLib  ./lib/foo.nix;
      # libbar = callLibs [./lib/bar-a.nix ./lib/bar-b.nix];
    };


# ---------------------------------------------------------------------------- #

    # Nixpkgs overlay: Builders, Packages, Overrides, etc.
    overlays.pkgs = final: prev: let
      callPackagesWith = auto: prev.lib.callPackagesWith ( final // auto );
      callPackageWith  = auto: prev.lib.callPackageWith ( final // auto );
      callPackages     = callPackagesWith {};
      callPackage      = callPackageWith {};
    in {
      lib = prev.lib.extend self.overlays.lib;
    };


# ---------------------------------------------------------------------------- #

    overlays.deps = ak-nix.overlays.ak-nix;
    # Reccomended for multiple input overlays:
    #   lib.composeManyExtensions [ak-nix.overlays.ak-nix ...];

    # By default, compose with our deps into a single overlay.
    overlays.default = lib.composeManyExtensions [
      self.overlays.deps
      self.overlays.pkgs
    ];


# ---------------------------------------------------------------------------- #

    # Installable Packages for Flake CLI.
    packages = eachSupportedSystemMap ( system: let
      pkgsFor = pkgsForSys system;
    in {

    } );


# ---------------------------------------------------------------------------- #

  };  # End Outputs
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
