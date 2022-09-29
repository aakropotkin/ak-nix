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

{ lib }: let

# ---------------------------------------------------------------------------- #

  # Cribbed from `flake-utils', vendored to skip a redundant fetch.

  defaultSystems = [
    "x86_64-linux" "x86_64-darwin"
    "aarch64-linux" "aarch64-darwin"
    "i686-linux"
  ];

  # Apply `fn' to each `system', forming an attrset keyed by system names.
  eachSystemMap = systems: fn:
    builtins.foldl' ( acc: sys: acc // { ${sys} = fn sys; } ) {} systems;

  eachDefaultSystemMap = eachSystemMap defaultSystems;


# ---------------------------------------------------------------------------- #

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


# ---------------------------------------------------------------------------- #

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
   

# ---------------------------------------------------------------------------- #

  # Convert an attrset to a list of `{ name : string, value }' pairs.
  attrsToList = as: let
    inherit (builtins) attrValues mapAttrs;
  in attrValues ( mapAttrs ( name: value: { inherit name value; } ) as );


# ---------------------------------------------------------------------------- #

  # Merges an attrset or list of sub-attrsets to a single attrset
  joinAttrs = {
    __funcitonMeta = {
      name = "joinAttrs";
      doc  = "Merges an attrset or list of sub-attrsets to a single attrset.";
      argc = 1;
      argsType = with lib.types;
        either ( listOf ( attrsOf anything ) )
               ( attrsOf ( attrsOf anything ) );
      returnType = with lib.types; attrsOf anything;
    };
    __processArgs = x: if builtins.isList x then x else builtins.attrValues x;
    __innerFunction = builtins.foldl' ( a: b: a // b ) {};
    __functor = self: x: self.__innerFunction ( self.__processArgs x );
  };


# ---------------------------------------------------------------------------- #

  # Rename keys in `attrs' using mapping in `kmap : { oldName = newName; ... }'.
  # Unmapped keys are not modified.
  remapKeys = kmap: attrs: let
    proc = acc: key:
      acc // { ${kmap.${key} or key} = attrs.${key}; };
  in builtins.foldl' proc ( builtins.attrNames attrs );

  # Remap keys using function `remap : string -> (string|null)'.
  # If remap returns `null' key will not be modified.
  remapKeysWith = remap: attrs: let
    proc = acc: key: let
      r   = remap key;
      new = if r == null then key else r;
    in acc // { ${r} = attrs.${key}; };
  in builtins.foldl' proc {} ( builtins.attrNames attrs );


# ---------------------------------------------------------------------------- #

  # Convert a list of attrs to and attrset keyed using `field'.
  listToAttrsBy = field: list: let
    proc = acc: value: acc // { ${value.${field}} = value; };
  in builtins.foldl' proc {} list;


# ---------------------------------------------------------------------------- #

  # Reduce an attrset using function `op' with prototype where `R' and `T' are
  # typenames of "Return" and "From".
  #   foldAttrs :: ( op : lambda ) -> ( nul : R ) -> ( attrs : { F } ) -> R
  #   op        :: ( acc : R ) -> ( key : string ) -> ( value : F ) -> R
  foldAttrsl = op: nul: attrs: let
    proc = acc: name: op acc name attrs.${name};
  in builtins.foldl' proc nul ( builtins.attrNames attrs );


# ---------------------------------------------------------------------------- #

in {
  inherit
    eachSystemMap eachDefaultSystemMap defaultSystems
    currySystems curryDefaultSystems
    funkSystems  funkDefaultSystems
    attrsToList
    joinAttrs
    remapKeys remapKeysWith
    listToAttrsBy
    foldAttrsl
  ;
}


/* ========================================================================== */
