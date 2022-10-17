# ============================================================================ #
#
# These helpers were graciously expropriated from
# The Virus Lounge: https://code.tvl.fyi/tree
#
# The following license has been carried from its original source:
#
# Copyright 2019 Google LLC
# SPDX-License-Identifier: Apache-2.0
#
#
# ---------------------------------------------------------------------------- #
#
# Provides a "type-system" for Nix that provides various primitive &
# polymorphic types as well as the ability to define & check records.
#
# All types (should) compose as expected.
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  prettyPrint = lib.generators.toPretty {};

# ---------------------------------------------------------------------------- #

  # typedef' :: struct {
  #   name = string;
  #   checkType = function; (a -> result)
  #   checkToBool = option function; (result -> bool)
  #   toError = option function; (a -> result -> string)
  #   def = option any;
  #   match = option function;
  # } -> type
  #           -> (a -> b)
  #           -> (b -> bool)
  #           -> (a -> b -> string)
  #           -> type
  #
  # This function creates an attribute set that acts as a type.
  #
  # It receives a type name, a function that is used to perform a
  # check on an arbitrary value, a function that can translate the
  # return of that check to a boolean that informs whether the value
  # is type-conformant, and a function that can construct error
  # messages from the check result.
  #
  # This function is the low-level primitive used to create types. For
  # many cases the higher-level 'typedef' function is more appropriate.
  typedef' = {
    name
  , checkType
  , checkToBool ? ( result: result.ok )
  , toError     ? ( _: result: result.err )
  , def         ? null
  , match       ? null
  }: {
    inherit name checkToBool toError;

    # check :: a -> bool
    #
    # This function is used to determine whether a given type is
    # conformant.
    check = value: checkToBool ( checkType value );

    # checkType :: a -> struct { ok = bool; err = option string; }
    #
    # This function checks whether the passed value is type conformant
    # and returns an optional type error string otherwise.
    inherit checkType;

    # __functor :: a -> a
    #
    # This function checks whether the passed value is type conformant
    # and throws an error if it is not.
    #
    # The name of this function is a special attribute in Nix that
    # makes it possible to execute a type attribute set like a normal
    # function.
    __functor = self: value: let
      result = self.checkType value;
    in if checkToBool result then value else throw ( toError value result );
  };


# ---------------------------------------------------------------------------- #

  # typedef :: string -> (a -> bool) -> type
  #
  # typedef is the simplified version of typedef' which uses a default
  # error message constructor.
  typedef = name: check: typedef' {
    inherit name;
    checkType = v: let
      res = check v;
    in {
      ok = res;
    } // ( lib.optionalAttrs ( ! res ) { err = typeError name v; } );
  };


# ---------------------------------------------------------------------------- #

  # Default error message for a type mismatch.
  typeError = type: val: let
    p  = prettyPrint val;
  in "expected type '${type}', but value '${p}' is of type '${builtins.typeOf val}'";


# ---------------------------------------------------------------------------- #

  # checkEach :: string -> type -> [any]
  checkEach = name: t: let
    proc = acc: e: let
      res    = t.checkType e;
      isType = t.checkToBool res;
    in {
      ok = acc.ok && isType;
      err = if isType then acc.err else
            acc.err + "${prettyPrint e}: ${t.toError e res}\n";
    };
    dft = { ok = true; err = "expected type ${name}, but found:\n"; };
  in builtins.foldl' proc dft;


# ---------------------------------------------------------------------------- #

  # Primitive Types
  #
  # The values in this attrset the predicate used for typechecking.
  Prim = ( builtins.mapAttrs ( k: p: typedef k p ) {
    any      = _: true;
    unit     = v: v == {};
    int      = builtins.isInt;
    bool     = builtins.isBool;
    float    = builtins.isFloat;
    string   = builtins.isString;
    path     = x: builtins.typeOf x == "path";
    function = x: let
      funky = ( builtins.isAttrs x ) &&
              ( builtins.isFunction ( x.__functor or null ) );
    in ( builtins.isFunction x ) || funky;

  # Type for types themselves. Useful when defining polymorphic types.
    type = x:
      ( builtins.isAttrs x )                            &&
      ( Prim.string.check   ( x.name        or null ) ) &&
      ( Prim.function.check ( x.checkType   or null ) ) &&
      ( Prim.function.check ( x.checkToBool or null ) ) &&
      ( Prim.function.check ( x.toError     or null ) );

  } ) // {
    # A Derivation is a special case of `set'.
    drv = let
      cond = x:
        ( builtins.isAttrs x ) &&
        ( ( x.type or null ) == "derivation" );
    in typedef "derivation" cond;
  };


# ============================================================================ #

  # Polymorphic types

  # <T> or `null'.
  Core.option = t: let
    name = "option<${t.name}>";
  in typedef' {
    inherit name;
    checkType = v: let
      res = t.checkType v;
    in {
      ok = ( v == null ) || ( ( Prim.type t ).checkToBool res );
      err = "expected type ${name}, but value does not conform to '${t.name}': "
            + ( t.toError v res );
    };
  };


# ---------------------------------------------------------------------------- #


  # One of [<T1>...<TN>]
  Core.eitherN = tn: let
    cond = x: builtins.any ( t: ( Prim.type t ).check x ) tn;
  in typedef "either<${builtins.concatStringsSep ", " (map (x: x.name) tn)}>" cond;


  # Either <T1> or <T2>
  Core.either = t1: t2: Core.eitherN [t1 t2];


# ---------------------------------------------------------------------------- #


  # List of <T>.
  Core.list = t: let
    name = "list<${t.name}>";
  in typedef' {
    inherit name;
    checkType = v:
      if builtins.isList v then checkEach name ( Prim.type t ) v else {
        ok  = false;
        err = typeError name v;
      };
  };


# ---------------------------------------------------------------------------- #


  # Attribute set of <T> values.
  Core.attrs = t: let
    name = "attrs<${t.name}>";
  in typedef' {
    inherit name;
    checkType = v:
      if builtins.isAttrs v
      then checkEach name ( Prim.type t ) ( builtins.attrValues v )
      else {
        ok = false;
        err = typeError name v;
      };
  };


# ============================================================================ #

  # Checks that all fields match their declared types, no optional
  # fields are missing and no unexpected fields occur in the struct.
  #
  # Anonymous structs are supported (e.g. for nesting) by omitting the
  # name.
  #
  # TODO: Support open records?
  Core.struct = let
    # Struct checking is more involved than the simpler types above.
    # To make the actual type definition more readable, several
    # helpers are defined below.

    # checkField checks an individual field of the struct against
    # its definition and creates a typecheck result. These results
    # are aggregated during the actual checking.
    checkField = def: name: value: let
      result = def.checkType value;
      ok     = def.checkToBool result;
    in {
      inherit ok;
      err =
        if ( ! ok ) && ( value == null )
        then "missing required ${def.name} field '${name}'\n"
        else "field '${name}': ${def.toError value result}\n";
    };

    # checkExtraneous determines whether a (closed) struct contains
    # any fields that are not part of the definition.
    checkExtraneous = def: has: acc:
      if ( builtins.length has ) == 0 then acc else
      if def ? ${builtins.head has}
      then checkExtraneous def ( builtins.tail has ) acc
      else checkExtraneous def ( builtins.tail has ) {
        ok = false;
        err = acc.err + "unexpected struct field '${builtins.head has}'\n";
      };

    # checkStruct combines all structure checks and creates one
    # typecheck result from them
    checkStruct = def: value: let
      init          = { ok = true; err = ""; };
      extraneous    = checkExtraneous def ( builtins.attrNames value ) init;
      checkedFields = let
        pred = n: let
          v = value.${n} or null;
        in checkField def.${n} n v;
      in map pred ( builtins.attrNames def );
      combined = let
        proc = acc: res: {
          ok  = acc.ok && res.ok;
          err = if ! res.ok then acc.err + res.err else acc.err;
        };
      in builtins.foldl' proc init checkedFields;
    in {
      ok  = combined.ok && extraneous.ok;
      err = combined.err + extraneous.err;
    };

    struct' = name: def: typedef' {
      inherit name def;
      checkType = value:
        if builtins.isAttrs value
        then checkStruct ( Core.attrs Prim.type def ) value
        else { ok = false; err = typeError name value; };
      toError = _: result:
        "expected '${name}'-struct, but found:\n" + result.err;
    };

  # If arg1 is a string interpret it as a typename, otherwise name it "anon".
  in arg: if builtins.isString arg then struct' arg else struct' "anon" arg;


# ============================================================================ #

  # Enums & pattern matching

  Core.enum = let
    plain = name: def: typedef' {
      inherit name def;
      checkType = x: ( builtins.isString x ) && ( builtins.elem x def );
      checkToBool = x: x;
      toError = value: _:
        "'${prettyPrint value} is not a member of enum ${name}";
    };
    enum' = name: def: lib.fix ( e: ( plain name def ) // {
      match = x: actions:
        builtins.deepSeq ( map e ( builtins.attrNames actions ) ) (
        let
          actionKeys = builtins.attrNames actions;
          missing = builtins.foldl' ( m: k:
            if ( builtins.elem k actionKeys ) then m else m ++ [k]
          ) [] def;
        in if 0 < ( builtins.length missing )
        then throw "Missing match action for members: ${prettyPrint missing}"
        else actions.${e x}
      );
    } );
  in arg: if builtins.isString arg then enum' arg else enum' "anon" arg;


# ---------------------------------------------------------------------------- #

  # Sum types
  #
  # The representation of a sum type is an attribute set with only one
  # value, where the key of the value denotes the variant of the type.
  Core.sum = let
    plain = name: def: typedef' {
      inherit name def;
      checkType = x: let
        variant = builtins.head ( builtins.attrNames x );
        t   = def."${variant}";
        v   = x."${variant}";
        res = t.checkType v;
      in if ( builtins.isAttrs x ) &&
            ( builtins.length ( builtins.attrNames x ) == 1 ) &&
            ( variant ? ${def} )
         then if t.checkToBool res then { ok = true; } else {
           ok = false;
           err = "while checking '${name}' variant '${variant}': "
             + t.toError v res;
         } else { ok = false; err = typeError name x; };
    };

    sum' = name: def: lib.fix ( s: ( plain name def ) // {
      match = x: actions: let
        variant = let
          name0 = builtins.head ( builtins.attrNames x );
        in builtins.deepSeq ( s x ) name0;
        actionKeys = builtins.attrNames actions;
        defKeys    = builtins.attrNames def;
        missing    = builtins.foldl' (m: k:
          if ( builtins.elem k actionKeys ) then m else m ++ [k]
        ) [] defKeys;
      in if 0 < ( builtins.length missing )
          then throw "Missing match action for variants: ${prettyPrint missing}"
          else actions."${variant}" x."${variant}";
    });
  in arg: if builtins.isString arg then sum' arg else sum' "anon" arg;


# ---------------------------------------------------------------------------- #

  # Typed function definitions
  #
  # These definitions wrap the supplied function in type-checking
  # forms that are evaluated when the function is called.
  #
  # Note that typed functions themselves are not types and can not be
  # used to check values for conformity.
  Core.defun = let
    mkFunc = sig: f: {
      inherit sig;
      __toString = self: builtins.foldl' ( s: t: "${s} -> ${t.name}" )
        "<LAMBDA> :: ${( builtins.head self.sig ).name}"
        ( builtins.tail self.sig );
      __functor = _: f;
    };
    defun' = sig: func:
      if 2 < ( builtins.length sig )
      then mkFunc sig (x: defun' (builtins.tail sig) (func ((builtins.head sig) x)))
      else mkFunc sig (x: ((builtins.head (builtins.tail sig)) (func ((builtins.head sig) x))));
  in sig: func:
     if ( builtins.length sig ) < 2
     then (throw "Signature must at least have two types (a -> b)")
     else defun' sig func;


# ---------------------------------------------------------------------------- #

  # Restricting types
  #
  # `restrict` wraps a type `t`, and uses a predicate `pred` to further
  # restrict the values, giving the restriction a descriptive `name`.
  #
  # First, the wrapped type definition is checked (e.g. int) and then the
  # value is checked with the predicate, so the predicate can already
  # depend on the value being of the wrapped type.
  Core.restrict = name: pred: t: let
    restriction = "${t.name}[${name}]";
  in typedef' {
    name = restriction;
    checkType = v: let
      res = t.checkType v;
      iok = pred v;
    in if ! ( t.checkToBool res ) then res else
       if builtins.isBool iok then {
         ok  = iok;
         err = "${prettyPrint v} does not conform to restriction '${restriction}'";
       } else
       # use throw here to avoid spamming the build log
       throw "restriction '${restriction}' predicate returned unexpected value '${prettyPrint iok}' instead of boolean";
  };


# ---------------------------------------------------------------------------- #

in {

  inherit Core Prim;

  # These were previously "private" in a `let ... in' block, presumably because
  # the authors thought the given typedefs were sufficient.
  __internal = { inherit typedef' typedef typeError checkEach prettyPrint; };

}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
