# ============================================================================ #
#
# Reference Flake Registry in Nix expressions ( Impure ).
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  registries = let
    paths = {
      global = let
        repo = builtins.fetchTree {
          type = "git";
          url = "https://github.com/NixOS/flake-registry";
        };
      in "${repo}/flake-registry.json";
      system = "/etc/nix/registry.json";
      user   = "${builtins.getEnv "HOME"}/.config/nix/registry.json";
    };
    fileExists = path:
      ( ! lib.inPureEvalMode ) && ( builtins.pathExists path );
    getReg = path: if ! fileExists path then {} else
      builtins.fromJSON ( builtins.readFile path );
  in builtins.mapAttrs ( _: getReg ) paths;


# ---------------------------------------------------------------------------- #

  lookupFlakeIn = { flakes ? [], ... } @ reg: id: let
    flt = builtins.filter ( { from, ... }: from.id == id ) flakes;
  in if ( builtins.length flt ) < 1 then null else builtins.head flt;

  lookupFlake = id: let
    u = lookupFlakeIn registries.user   id;
    s = lookupFlakeIn registries.system id;
    g = lookupFlakeIn registries.global id;
  in if u != null then u else if s != null then s else g;


# ---------------------------------------------------------------------------- #

  registryFlakes = let
    asAttrs = { from, to }: { name = from.id; value = to; };
    flakes  = ( registries.global.flakes or [] ) ++
              ( registries.system.flakes or [] ) ++
              ( registries.user.flakes or [] );
  in builtins.listToAttrs ( map asAttrs flakes );


# ---------------------------------------------------------------------------- #

in lib.optionalAttrs ( ! lib.inPureEvalMode ) {
  inherit
    registries
    registryFlakes
  ;
}
