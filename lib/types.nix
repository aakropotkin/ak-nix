# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  yt = lib.ytypes // lib.ytypes.Prim // lib.ytypes.Core;

# ---------------------------------------------------------------------------- #

  # Create a `discrDef' tagger for a group of types.
  # ( [ytype] | {tag: ytype} ) -> string -> value -> {tag: value}
  #
  # Examples:
  #   let dt = discrDefTypes [yt.bool yt.string] "unknown";
  #   in map dt ["hey" false 3]
  #   => [{ string = "hey" } { bool = false } { unknown = 3 }]
  #
  #   let dt = discrDefTypes { Buul = yt.bool; Strang = yt.string; } "dunno";
  #   in map dt ["hey" false 3]
  #   => [{ Strang = "hey" } { Buul = false } { dunno = 3 }]
  discrDefTypes = types: let
    fromList  = map ( { name, check, ... }: { ${name} = check; } ) types;
    fromAttrs = map ( tag: { ${tag} = types.${tag}.check; } )
                    ( builtins.attrNames types );
    fs = if builtins.isList types then fromList else fromAttrs;
  in defTag: ( lib.libtag.discrDef defTag fs );


  # Same as above, but no default tag.
  # Failing to match throws an error.
  #
  # Examples:
  #   let dt = discrTypes [yt.bool yt.string];
  #   in map dt ["hey" false 3]
  #   => [{ string = "hey" } { bool = false }];
  #
  #   let dt = discrTypes { Buul = yt.bool; Strang = yt.string; };
  #   in map dt ["hey" false 3]
  #   => [{ Strang = "hey" } { Buul = false } error: ...]
  discrTypes = types: let
    fromList  = map ( { name, check, ... }: { ${name} = check; } ) types;
    fromAttrs = map ( tag: { ${tag} = types.${tag}.check; } )
                    ( builtins.attrNames types );
    fs = if builtins.isList types then fromList else fromAttrs;
  in lib.libtag.discr fs;


# ---------------------------------------------------------------------------- #



# ---------------------------------------------------------------------------- #

  Prim = {
    nil = yt.Prim.unit // {
      name = "nil";
      checkType = v: {
        ok  = v == null;
        err = "expected 'null', but value is of type '${builtins.typeOf v}'";
      };
    };
  };

  Typeclasses = {

    stringable = yt.Prim.string // {
      name = "stringable";
      checkType = v: {
        ok  = ( builtins.isString v ) ||
              ( ( v ? __toString ) && ( builtins.isFunction v.__toString ) );
        err = "expected a string, or an attrset with the functor '__toString', "
              + "but value is of type '${builtins.typeOf v}'";
      };
    };

    serializable = yt.Prim.unit // {
      name = "serializable";
      checkType = v: let
        errGeneric = "expected an attrset with the functor '__serial', but ";
        errType    = "value is of type '${builtins.typeOf v}'";
        errNotFn   = "'__serial' is of type '${builtins.typeOf v.__serial}'";
      in {
        ok  = ( builtins.isAttrs v ) &&
              ( ( v ? __serial ) && ( ( lib.isFunction v.__serial ) ) );
        err = errGeneric + ( if v ? __serial then errNotFn else errType );
      };
    };

    functor = yt.Prim.function // {
      name      = "functor";
      checkType = v: let
        errGeneric = "expected an attrset with the functor '__functor', but ";
        errType    = "value is of type '${builtins.typeOf v}'";
        errNotFn   = "'__functor' is of type '${builtins.typeOf v.__functor}'";
      in {
        ok  = ( builtins.isAttrs v ) &&
              ( ( v ? __functor ) && ( ( lib.isFunction v.__functor ) ) );
        err = errGeneric + ( if v ? __functor then errNotFn else errType );
      };
    };

  };  # End Typeclasses


# ---------------------------------------------------------------------------- #

  # Creates an extended `sum' type which carries a `case' statement matcher
  # keyed by types.
  #
  # Example:
  # let
  #   boolOrStringly = sumCase "boolOrStringly" {
  #     inherit bool;
  #     Stringly = string;
  #   };
  #   m = { bool = x: if x then 4 else 20; Stringly = x: "${x}: it"; };
  # in boolOrStringly.case "blaze" m;
  # => "blaze: it"
  sumCase = name: types: let
    self = ( yt.sum name types ) // {
      disc = discrTypes types;
      case = val: self.match ( self.disc val );
    };
  in self;


# ---------------------------------------------------------------------------- #

in {
  inherit
    discrDefTypes
    discrTypes
    sumCase
  ;
  ytypes = {
    inherit Prim Typeclasses;
    inherit sumCase;
  };
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
