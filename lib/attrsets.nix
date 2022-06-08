/* ========================================================================== */
# Example Usage:
#   nix-repl> add = curryDefaultSystems' ( system: { x, y }: builtins.trace system ( x + y ) )
#
#   nix-repl> add { x = 1; y = 2; }
#   { __functor = <lambda>; aarch64-darwin = trace: aarch64-darwin
#   3; aarch64-linux = trace: aarch64-linux
#   3; i686-linux = trace: i686-linux
#   3; x86_64-darwin = trace: x86_64-darwin
#   3; x86_64-linux = trace: x86_64-linux
#   3; }
#
#   nix-repl> ( add { x = 1; y = 2; } ) "x86_64-linux"
#   trace: x86_64-linux
#   3


{ utils ? builtins.getFlake "github:numtide/flake-utils" }:

let

   inherit (utils.lib) eachDefaultSystemMap eachSystemMap defaultSystems;

/* -------------------------------------------------------------------------- */

   currySystems = supportedSystems: fn: args: let
      fas    = builtins.functionArgs fn;
      callAs = system: fn ( { inherit system; } // args );
      callV  = system: fn system args;
      apply  = if ( fas == {} ) then callV else if ( fas ? system ) then callAs
               else throw "provided function cannot accept system as an arg";
      sysAttrs = eachSystemMap supportedSystems apply;
      curried  = { __functor = self: system: self.${system}; };
   in sysAttrs // curried;

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

in {

   inherit currySystems curryDefaultSystems;
   inherit funkSystems funkDefaultSystems;

}  /* End `attrsets.nix' */


/* ========================================================================== */
