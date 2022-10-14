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

  yt = lib.ytypes // lib.ytypes.Core // lib.ytypes.Prim;

# ---------------------------------------------------------------------------- #

  # Apply `fn' to each `system', forming an attrset keyed by system names.
  eachSystemMap = systems: fn:
    builtins.foldl' ( acc: sys: acc // { ${sys} = fn sys; } ) {} systems;

  eachDefaultSystemMap = eachSystemMap lib.defaultSystems;


# ---------------------------------------------------------------------------- #

  pushDownNames = builtins.mapAttrs ( name: val: val // { inherit name; } );


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
      argsType   = yt.either ( ( yt.list  yt.any ) ( yt.attrs yt.any ) );
      returnType = yt.attrs yt.any;
    };
    __processArgs   = x: if builtins.isList x then x else builtins.attrValues x;
    __innerFunction = builtins.foldl' ( a: b: a // b ) {};
    __functor       = self: x: self.__innerFunction ( self.__processArgs x );
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
    pushDownNames
    eachSystemMap eachDefaultSystemMap
    attrsToList
    joinAttrs
    remapKeys remapKeysWith
    listToAttrsBy
    foldAttrsl
  ;
}


/* ========================================================================== */
