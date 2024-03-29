# ============================================================================ #
#
# CHANGE: Look for any `CHANGEME' blocks and replace things like `NAME' with
#         your flake's name.
#
# ---------------------------------------------------------------------------- #

{

# ---------------------------------------------------------------------------- #

  description = "A dank starter flake";


# ---------------------------------------------------------------------------- #

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";


# ---------------------------------------------------------------------------- #

  outputs = { nixpkgs, ... }: let

# ---------------------------------------------------------------------------- #

    eachDefaultSystemMap = fn: let
      defaultSystems = [
        "x86_64-linux"  "aarch64-linux"  "i686-linux"
        "x86_64-darwin" "aarch64-darwin"
      ];
      proc = system: { name = system; value = fn system; };
    in builtins.listToAttrs ( map proc defaultSystems );


# ---------------------------------------------------------------------------- #

    inherit (nixpkgs) lib;


# ---------------------------------------------------------------------------- #

    # Aggregate dependency overlays here.
    
    ## CHANGEME
    
    # If you only need `nixpkgs.legacyPackages', use this
    overlays.deps = final: prev: {};

    ## If you only need a single extension, use this and change `INPUT'
    ##overlays.deps = INPUT.overlays.default;
    
    ## If you need two, use this and change `INPUT#'s.
    ##overlays.deps = lib.composeExtensions INPUT0.overlays.default
    ##                                      INPUT1.overlays.default;

    ## If you need many, use this and change `INPUT#s's
    ##overlays.deps = lib.composeManyExtensions [
    ##  INPUT0.overlays.default
    ##  INPUT1.overlays.default
    ##  INPUT2.overlays.default
    ##];


# ---------------------------------------------------------------------------- #

    # Define our overlay
  
    # CHANGEME
    
    overlays.NAME = final: prev: {
      ## NAME = final.callPackage ./default.nix {};
    };

    
    # Make our default overlay as `deps + NAME'.
    overlays.default = lib.composeExtensions overlays.deps overlays.NAME;


# ---------------------------------------------------------------------------- #

  in {

    inherit lib overlays;

    # Installable Packages for Flake CLI.
    packages = eachDefaultSystemMap ( system: let
      pkgsFor = nixpkgs.legacyPackages.${system}.extend overlays.default;
    in {
      # CHANGEME
      inherit (pkgsFor) NAME;
    } );



  };  # End `outputs'


# ---------------------------------------------------------------------------- #

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
