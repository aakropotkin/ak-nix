/* ========================================================================== */

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

   funkSystems = funkSystems defaultSystems;
   

/* -------------------------------------------------------------------------- */

in {

   inherit currySystems curryDefaultSystems;
   inherit funkSystems funkSystems;

}  /* End `attrsets.nix' */


/* ========================================================================== */
