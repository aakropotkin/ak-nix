# ============================================================================ #
#
# Example Usage:
#   nix-repl> add = curryDefaultSystems' ( system:
#                     { x, y }: builtins.trace system ( x + y ) )
#
#   nix-repl> add { x = 1; y = 2; }
#   { __functor      = <lambda>;
#     aarch64-darwin = 3; trace: aarch64-darwin
#     aarch64-linux  = 3; trace: aarch64-linux
#     i686-linux     = 3; trace: i686-linux
#     x86_64-darwin  = 3; trace: x86_64-darwin
#     x86_64-linux   = 3; trace: x86_64-linux
#   }
#
#   nix-repl> ( add { x = 1; y = 2; } ) "x86_64-linux"
#   trace: x86_64-linux
#   3
#
#
# ---------------------------------------------------------------------------- #

{ lib
, utils ? builtins.getFlake "github:numtide/flake-utils"
, nix   ? builtins.getFlake "github:NixOS/nix"
}: let

  inherit (utils.lib) eachDefaultSystemMap eachSystemMap defaultSystems;

  currySystems = supportedSystems: fn: args: let
    inherit (builtins) functionArgs isString elem;
    fas    = functionArgs fn;
    callAs = system: fn ( { inherit system; } // args );
    callV  = system: fn system args;
    isSys  = ( isString args ) && ( elem args supportedSystems );
    callF  = _: args': fn args args';  # Flip
    apply  =
      if ( fas == {} ) then if isSys then callF else callV else
      if ( fas ? system ) then callAs else
      throw "provided function cannot accept system as an arg";
    sysAttrs = eachSystemMap supportedSystems apply;
    curried  = { __functor = self: system: self.${system}; };
    curriedF = { __functor = self: args': self.${args} args'; };
  in sysAttrs // ( if isSys then curriedF else curried );

  curryDefaultSystems = currySystems defaultSystems;


/* -------------------------------------------------------------------------- */

  funkSystems = supportedSystems: fn: let
    fas    = builtins.functionArgs fn;
    callAs = system: fn { inherit system; };
    callV  = system: fn system;
    apply  = if ( fas == {} ) then callV else if ( fas ? system ) then callAs
             else throw "provided function cannot accept system as an arg";
    sysAttrs = eachSystemMap supportedSystems apply;
    curried  = { __functor = self: system: self.${system}; };
  in sysAttrs // curried;

  funkDefaultSystems = funkSystems defaultSystems;
   

/* -------------------------------------------------------------------------- */

  attrsToList = as: let
    inherit (builtins) attrValues mapAttrs;
  in attrValues ( mapAttrs ( name: value: { inherit name value; } ) as );


/* -------------------------------------------------------------------------- */

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


/* -------------------------------------------------------------------------- */

in {
  inherit
    currySystems curryDefaultSystems
    funkSystems funkDefaultSystems
    attrsToList
    callFlakeWith callFlake
  ;
}  /* End `attrsets.nix' */


/* ========================================================================== */
