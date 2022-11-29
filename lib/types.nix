# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  yt = lib.ytypes // lib.ytypes.Prim // lib.ytypes.Core;

# ---------------------------------------------------------------------------- #

  discrDefTypes = {
    __functionMeta = {
      name = "discrDefTypes";
      from = "ak-nix#lib.libtypes";
      signature = let
        typeList = yt.list yt.type;
        tagAttrs = yt.attrs yt.type;
        arg0     = yt.either typeList tagAttrs;
      in [arg0 yt.string yt.any ( yt.attrs yt.any )];
      doc = ''
discrDefTypes  TYPES/TAGS -> DEFAULT -> VALUE -> TAGGED-VALUE
Create a `discrDef' tagger for a group of types with a fallback tag.

( [ytype] | {tag: ytype} ) -> string -> T<any> -> {tag: T<any>}

For a list of types we use the typenames as the tags.
Alternative tags can be used by passing in an attrset of types.
The second arg is a "default"/fallback tag to be used if no checks match.
This is the same as `discrTypes' except failing to match is not an error.

Examples:
  let dt = discrDefTypes [yt.bool yt.string] "unknown";
  in map dt ["hey" false 3]
  => [{ string = "hey" } { bool = false } { unknown = 3 }]

  let dt = discrDefTypes { Buul = yt.bool; Strang = yt.string; } "dunno";
  in map dt ["hey" false 3]
  => [{ Strang = "hey" } { Buul = false } { dunno = 3 }]
      '';
    };
    __processArgs = self: types: let
      fromList  = map ( { name, check, ... }: { ${name} = check; } ) types;
      fromAttrs = map ( tag: { ${tag} = types.${tag}.check; } )
                      ( builtins.attrNames types );
    in if builtins.isList types then fromList else fromAttrs;

    __innerFunction = checks: defTag: ( lib.libtag.discrDef defTag checks );

    __functor = self: x: let
      checks  = self.__processArgs self x;
    in self.__innerFunction checks;
  };


  # Same as above, but no default tag.
  # Failing to match throws an error.
  discrTypes = discrDefTypes // {
    __functionMeta = {
      name = "discrTypes";
      from = "ak-nix#lib.libtypes";
      signature = let
        typeList = yt.list yt.type;
        tagAttrs = yt.attrs yt.type;
        arg0     = yt.either typeList tagAttrs;
      in [arg0 yt.any ( yt.attrs yt.any )];
      doc = ''
discrTypes  TYPES/TAGS -> VALUE -> TAGGED-VALUE
Create a `discr' tagger for a group of types.
This is the same as `discrDefTypes' except failing to match throws an error.

( [ytype] | {tag: ytype} ) -> T<any> -> {tag: T<any>}

For a list of types we use the typenames as the tags.
Alternative tags can be used by passing in an attrset of types.

Examples:
  let dt = discrTypes [yt.bool yt.string];
  in map dt ["hey" false 3]
  => [{ string = "hey" } { bool = false }];

  let dt = discrTypes { Buul = yt.bool; Strang = yt.string; };
  in map dt ["hey" false 3]
  => [{ Strang = "hey" } { Buul = false } error: ...]
      '';
    };
    __innerFunction = checks: ( lib.libtag.discr checks );
  };


# ---------------------------------------------------------------------------- #

  # Apply a tagged function to a value based on its primitive type.
  # The "any" type will be used as a fallback but it need not be defined,
  # failing to match will throw an error though.
  #   discrTypesMatchLam { string = s: s + " there"; any = x: x; } "hi"
  #   => "hi there"
  discrTypesMatchLam = types: matcher: let
    inner  = x: lib.libtag.match ( discrDefTypes types "any" x ) matcher;
    genMsg = wrong: right:
      "The tag \"${wrong}\" found in `matcher' is not a primitive. " +
      "Did you mean \"${right}\"?";
    misnomers = {
      attrset  = "attrs";
      struct   = "attrs";
      record   = "attrs";
      fields   = "attrs";
      set      = "attrs";
      unit     = "attrs";
      tag      = "attrs";
      "null"   = "nil";
      empty    = "nil";
      void     = "nil";
      number   = "int' or `float";
      num      = "int' or `float";
      integer  = "int";
      decimal  = "float";
      double   = "float";
      default  = "any";
      _default = "any";
      functor  = "function";
      lambda   = "function";
      file     = "path";
      str      = "string";
    };
    bads    = builtins.attrNames ( builtins.intersectAttrs matcher misnomers );
    mproc   = msgs: wrong: msgs + "\n" + ( genMsg wrong misnomers.${wrong} );
    msg     = builtins.foldl' mproc "" bads;
  in if bads == {} then inner else throw msg;

  # As above but it is an error to omit the `any' type.
  discrDefTypesMatchLam = types: matcher:
    if matcher ? any  then discrTypesMatchLam types matcher else
    throw ( "(ak-nix#lib.libtypes.discrDefTypesMatchLam): You must provide "
            + "a matcher for the 'any' type to use for fallbacks." );


# ---------------------------------------------------------------------------- #

  # Identify/"tag" a value with its primitive type.
  # NOTE: `unit' is excluded and the value `{}' will return "attrs".
  #   discrPrims "hi" => { string = "hi"; }
  discrPrims = discrTypes ( ( removeAttrs lib.ytypes.Prim ["any" "unit"] ) // {
    attrs = yt.attrs yt.any;
    list  = yt.list yt.any;
  } );


  discrPrimsMatchLam = matcher: x: let
    tagged = discrPrims x;
    tn     = lib.libtag.tagName tagged;
  in ( matcher.${tn} or matcher.any ) x;


# ---------------------------------------------------------------------------- #

  # A more useful `sum' type with a member similar to `<SUM>.match' except that
  # it acutally makes sense.
  # Lord knows what `<SUM>.match' was intended to do... probably this.
  Core.sumCase = {
    __functionMeta = {
      name = "sumCase";
      from = "ak-nix#lib.libtypes";
      signature = [yt.string ( yt.attrs yt.type ) yt.type];
      properties.family = "typedef";
      doc = ''
sumCase  NAME -> TAGGED-TYPES -> TYPE
Creates an extended `sum' type which carries a `case' statement matcher
keyed by types.

Example:
  let
    boolOrStringly = sumCase "boolOrStringly" {
      inherit bool;
      Stringly = string;
    };
    m = { bool = x: if x then 4 else 20; Stringly = x: "''${x}: it"; };
  in [
    ( boolOrStringly.case "blaze" m )
    ( map ( boolOrStringly.switch m ) [true "loud" false] )
  ];
  => [ "blaze: it" [4 "loud: it" 20]]
      '';
    };
    __innerFunction = name: types: let
      self = ( yt.sum name types ) // {
        discr  = discrTypes types;
        case   = val: self.match ( self.discr val );
        switch = matcher: val: self.match ( self.discr val ) matcher;
      };
    in self;
    __functor = self: self.__innerFunction;
  };


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

# ---------------------------------------------------------------------------- #

    pathlike = yt.__internal.typedef' {
      name    = "pathlike";
      toError = v: { type, ok } @ result: {
        string = "expected a pathlike type, and while value is a string - "
                  + "it must begin with '.' or '/', but we got \"${v}\"";
        attrs = "expected a pathlike type, and while an attrset can be " +
                "pathlike - it must set 'outPath' or '__toString', but" +
                " value was: " + ( lib.generators.toPretty {} v );
        any =
          yt.__internal.typeError "pathlike ( string, path, or {outPath} )" v;
      }.${type};
      checkType = v: let
        matcher = {
          string = lib.test "[./].*";
          path   = _: true;
          attrs  = x: let
            type = x.type or x._type or null;
          in ( x ? outPath ) || ( builtins.elem type ["path" "pathlike"] ) ||
             ( ( x ? __toString ) && ( lib.test "[./].*" ( toString x ) ) );
        };
        tagged = discrPrims v;
        tag    = lib.tagName tagged;
      in {
        type   = if matcher ? ${tag} then tag else "any";
        ok = ( matcher ? ${tag} ) && ( lib.libtag.match tagged matcher );
      };
    };


# ---------------------------------------------------------------------------- #

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


# ---------------------------------------------------------------------------- #

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


# ---------------------------------------------------------------------------- #

    functor = yt.Prim.function // {
      name      = "functor";
      checkType = v: let
        errGeneric = "expected an attrset with the functor '__functor', but ";
        errType    = "value is of type '${builtins.typeOf v}'";
        errNotFn   = "'__functor' is of type '${builtins.typeOf v.__functor}'";
      in {
        ok = ( builtins.isAttrs v ) &&
             ( ( v ? __functor ) && ( lib.isFunction v.__functor ) );
        err = errGeneric + ( if v ? __functor then errNotFn else errType );
      };
      check = v: ( Typeclasses.functor.checkType v ).ok;
    };


# ---------------------------------------------------------------------------- #

    extensible = let
      cond = x:
        ( builtins.isAttrs x ) &&
        ( builtins.isFunction ( x.extend or x.__extend or null ) ) &&
        ( builtins.isFunction ( x.__unfix__ or null ) );
    in yt.__internal.typedef "extensible" cond;


# ---------------------------------------------------------------------------- #

  };  # End Typeclasses


# ---------------------------------------------------------------------------- #

in lib.ytypes.__internal // {
  inherit
    discrDefTypes
    discrTypes
    discrPrims
    discrTypesMatchLam
    discrDefTypesMatchLam
  ;

  dtmatchL     = discrTypesMatchLam;
  dPrims       = discrPrims;
  dPrimsMatchL = discrPrimsMatchLam;

  inherit (Core)
    sumCase
  ;
  ytypes = {
    inherit Prim Typeclasses Core;
    store_pathlike = let
      cond = x: ( builtins.isPath x ) ||
                ( builtins.hasContext ( toString x ) ) ||
                ( lib.isStorePath ( toString x ) );
    in yt.restrict "nix-store" cond lib.ytypes.Typeclasses.pathlike;
    # TODO: process `allowedPaths'
    impure_pathlike = let
      cond = x: ! ( lib.ytypes.Typeclasses.store_pathlike.check x );
    in yt.restrict "impure" cond lib.ytypes.Typeclasses.pathlike;
  };
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
