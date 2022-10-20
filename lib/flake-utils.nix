# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  # Like `callPackageWith' but for flakes.
  # This allows you to stash a "thunk" of auto-called args, and pass overrides
  # at the end.
  #
  # An example of re-calling `ak-nix' flake from some other flake
  # using the inputs of the caller "self" as a base, then overriding `nixpkgs'
  # to make `ak-nix' follow one of our inputs' instance.
  #   ak-nix-custom = callFlakeWith self.inputs  {
  #     nixpkgs = self.inputs.bar.inputs.nixpkgs;
  #   };
  #
  # Also try calling with your registries ( see [[file:./flake-registry.nix]] ):
  #   builtins.mapAttrs ( _: builtins.fetchTree ) lib.libflake.registryFlakeRefs
  callFlakeWith = autoArgs: refOrDir: extraArgs: let
    ftSrc    = builtins.fetchTree ( removeAttrs refOrDir ["dir"] );
    fromFt   = if refOrDir ? dir then "${ftSrc}/${refOrDir.dir}" else ftSrc;
    flakeDir =
      if lib.isStorePath refOrDir       then refOrDir else
      if lib.isCoercibleToPath refOrDir then refOrDir else
      if builtins.isAttrs refOrDir then fromFt else
      throw "This doesn't look like a path";
    flake  = import "${flakeDir}/flake.nix";
    inputs = let
      inherit (builtins) functionArgs intersectAttrs;
      lock       = lib.importJSONOr { nodes = {}; } "${flakeDir}/flake.lock";
      fetchInput = { locked, ... }: builtins.fetchTree locked;
      locked     = builtins.mapAttrs ( id: fetchInput ) lock.nodes;
      stdArgs    = locked // autoArgs // { inherit self; };
    in lib.canPassStrict stdArgs flake.outputs;
    self = flake // ( flake.outputs ( inputs // extraArgs ) );
  in self;

  callFlake = callFlakeWith {};


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
