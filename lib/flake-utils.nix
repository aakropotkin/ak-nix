# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib
, nix ? builtins.getFlake "github:NixOS/nix"
}: let

# ---------------------------------------------------------------------------- #

  # Recommended: `callFlakeWith self.inputs "foo" { someOverride = ...; }'
  callFlakeWith = autoArgs: path: args: let
    flake = import "${path}/flake.nix";
    inputs = let
      inherit (builtins) functionArgs intersectAttrs;
      lock       = lib.importJSON "${path}/flake.lock";
      fetchInput = { locked, ... }: builtins.fetchTree locked;
      locked     = builtins.mapAttrs ( id: fetchInput ) lock.nodes;
      all        = locked // autoArgs // { self = fSelf; };
    in ( intersectAttrs ( functionArgs flake.outputs ) all ) // args;
    fSelf = flake // ( flake.outputs inputs );
  in fSelf;

  callFlake = callFlakeWith {};

  # XXX: Not sure if it makes sense to make these implementations align or not.
  # They basically do the exact same thing though; the main difference is that
  # `callSubFlake' handles `follows' correct AFAIK.
  # { lock ? <PATH>, root ? <PATH>, subdir ? <REL-PATH> }
  callSubFlake' = import ./call-flake-w.nix { inherit nix; };


# ---------------------------------------------------------------------------- #

  # Non-flake inputs don't contain a `sourceInfo' field, because they are the
  # `sourceInfo' record itself.
  # This allows us to detect which inputs are flakes and which arent.
  # The alternative approach is importing your own lock and scraping for the
  # field `flake = <bool>' in the nodes which is a pain in the ass.
  inputIsFlake = input: assert input ? narHash;
    ( input ? sourceInfo );


# ---------------------------------------------------------------------------- #

in {
  inherit
    callFlakeWith
    callFlake
    inputIsFlake
  ;
}  /* End `attrsets.nix' */


/* ========================================================================== */
