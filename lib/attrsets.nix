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

  # Parse a string like `foo.bar."baz.quux".fizz."buzz"' to an attrpath,
  # ["foo" "bar" "baz.quux" "fizz" "buzz"]
  parseAttrPath = str: let
    dropEmpty = builtins.filter ( x: x != "" );
    esc  = dropEmpty ( builtins.split "\"([^\"]*)\"" str );
    proc = acc: x:
      if builtins.isList x then acc ++ x else
      acc ++ ( dropEmpty ( lib.splitString "." x ) );
  in builtins.foldl' proc [] esc;


  # getAttrByStr "foo.\"bar.baz\".quux" { foo."bar.baz".quux = 420; } => 420
  getAttrByStr = s: builtins.getAttr ( parseAttrPath s );


# ---------------------------------------------------------------------------- #

  # Filter out equal attrs recursively.
  # Returns two top level attrs { _A = { ... }; _B = { ... }; }' containing the
  # differing fields found in each attrset.
  #
  # diffAttrs { x = 1; y = 2; } { x = 1; y = 3; z = 4; }
  # =>
  # {
  #   _A.y = 2;
  #   _B = {
  #     y = 3;
  #     z = 4;
  #   };
  # }
  diffAttrs = a: b: let
    comm       = builtins.intersectAttrs a b;
    different  = lib.filterAttrs ( k: bv: a.${k} != bv ) comm;
    proc = acc: k: let
      sub = diffAttrs a.${k} b.${k};
      add = if ( builtins.isAttrs b.${k} ) && ( builtins.isAttrs a.${k} )
            then diffAttrs a.${k} b.${k}
            else { _A.${k} = a.${k}; _B.${k} = b.${k}; };
    in { _A = ( acc._A or {} ) // add._A; _B = ( acc._B or {} ) // add._B; };
    diff = builtins.foldl' proc {} ( builtins.attrNames different );
  in {
    _A = ( removeAttrs a ( builtins.attrNames comm ) ) // ( diff._A or {} );
    _B = ( removeAttrs b ( builtins.attrNames comm ) ) // ( diff._B or {} );
  };


# ---------------------------------------------------------------------------- #

  # Apply functions held in fields of first arg to values of matching fields in
  # second arg.
  # Unmatched fields in second arg are unmodified.
  #
  # applyAttrs { x = prev: prev * 2; y = prev: prev / 2; } { x = 1; y = 3; }
  # =>
  # { x = 2; y = 1; }
  applyAttrs = fns: set: let
    comm    = builtins.intersectAttrs fns set;
    applied = builtins.mapAttrs ( k: v: fns.${k} v ) comm;
  in set // applied;


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
    parseAttrPath
    getAttrByStr
    diffAttrs
    applyAttrs
  ;
}


/* ========================================================================== */
