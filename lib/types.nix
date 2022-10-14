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
  # in [
  #   ( boolOrStringly.case "blaze" m )
  #   ( map ( boolOrStringly.switch m ) [true "loud" false] )
  # ];
  # => [ "blaze: it" [4 "loud: it" 20]]
  sumCase = name: types: let
    self = ( yt.sum name types ) // {
      discr  = discrTypes types;
      case   = val: self.match ( self.discr val );
      switch = matcher: val: self.match ( self.discr val ) matcher;
    };
  in self;


# ---------------------------------------------------------------------------- #

  Prim = {
    nil = yt.Prim.unit // {
      name = "nil";
      checkType = v: {
        ok  = v == null;
        err = "expected 'null', but value is of type '${builtins.typeOf v}'";
      };
      check = v: ( Prim.nil.checkType v ).ok;
    };
  };


# ---------------------------------------------------------------------------- #

  Typeclasses = {

    pathlike = yt.Prim.unit // {
      name = "pathlike";
      checkType = v: let
        mt = {
          string = lib.test "[./].*";
          path   = _: true;
          set    = x:
            ( x ? outPath ) || 
            ( ( x.type or x._type or null ) == "path" ) ||
            ( ( x ? __toString ) && ( mt.string ( toString x ) ) );
        };
        bt   = builtins.typeOf v;
        okBt = builtins.elem bt ( builtins.attrNames mt );
        me   = {
          string = "expected a pathlike type, and while value is a string - "
                   + "it must begin with '.' or '/', but we got '${v}'";
          set = "expected a pathlike type, and while an attrset can be " +
                "pathlike - it must set 'outPath' or '__toString', but" +
                " value was: " + ( lib.generators.toPretty {} v );
        };
      in {
        ok  = okBt && ( mt.${bt} v );
        err = if okBt then me.${bt} else
              "expected a pathlike type ( set, string, or path ), but value " +
              " is of type '${bt}'";
      };
      check = v: ( Typeclasses.pathlike.checkType v ).ok;
    };

    stringy = yt.Prim.string // {
      name = "stringy";
      checkType = v: {
        ok  = ( builtins.isString v ) ||
              ( ( v ? __toString ) && ( builtins.isFunction v.__toString ) );
        err = "expected a string, or an attrset with the functor '__toString', "
              + "but value is of type '${builtins.typeOf v}'";
      };
      check = v: ( Typeclasses.stringy.checkType v ).ok;
    };

    serializable = yt.Prim.unit // {
      name = "serializable";
      checkType = v: let
        errGeneric = "expected an attrset with the functor '__serial', but ";
        errType    = "value is of type '${builtins.typeOf v}'";
        errNotFn   = "'__serial' is of type '${builtins.typeOf v.__serial}'";
      in {
        ok  = ( builtins.isAttrs v ) &&
              ( ( v ? __serial ) && ( lib.isFunction v.__serial ) );
        err = errGeneric + ( if v ? __serial then errNotFn else errType );
      };
      check = v: ( Typeclasses.serializable.checkType v ).ok;
    };

    functor = yt.Prim.function // {
      name      = "functor";
      checkType = v: let
        errGeneric = "expected an attrset with the functor '__functor', but ";
        errType    = "value is of type '${builtins.typeOf v}'";
        errNotFn   = "'__functor' is of type '${builtins.typeOf v.__functor}'";
      in {
        ok  = ( builtins.isAttrs v ) &&
              ( ( v ? __functor ) && ( lib.isFunction v.__functor ) );
        err = errGeneric + ( if v ? __functor then errNotFn else errType );
      };
      check = v: ( Typeclasses.functor.checkType v ).ok;
    };

  };  # End Typeclasses


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
