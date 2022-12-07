# ============================================================================ #
#
# Function and Functor Fuckery.
#
# Creates abstractions for complex functions and functors ( funks ), and
# allows them to be constructed with "factories".
#
# This expands on parts of Nixpkgs' `lib/customization.nix', adding functor
# meta fields, "thunks" ( similar to overrides ), argument processors, wrapper
# generators, and more.
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  yt = lib.ytypes // lib.ytypes.Core // lib.ytypes.Prim;
  inherit (lib.ytypes.Typeclasses) functor;

# ---------------------------------------------------------------------------- #
#
# Nixpkgs routines included for reference.
#
#
#  setFunctionArgs = f: args: {
#    __functor      = self: f;
#    __functionArgs = args;
#  };
#
#  # XXX: Pay attention to how they pull args from the functor!
#  functionArgs = f:
#    if f ? __functor
#    then f.__functionArgs or ( lib.functionArgs ( f.__functor f ) )
#    else builtins.functionArgs f;
#
#  isFunction = f:
#    ( builtins.isFunction f ) ||
#    ( ( f ? __functor ) && ( isFunction ( f.__functor f ) ) );
#
#
# ---------------------------------------------------------------------------- #

  inherit (lib) setFunctionArgs functionArgs isFunction;

# ---------------------------------------------------------------------------- #

  mandatoryArgsStrict = fn:
    lib.filterAttrs ( name: optional: ! optional ) ( lib.functionArgs fn );

  # Taken from Nixpkgs' `lib.callPackageWith'
  missingArgsStrict = fn: args: let
    sat = name: optional: ! ( optional || ( args ? ${name} ) );
  in lib.filterAttrs sat ( lib.functionArgs fn );


# ---------------------------------------------------------------------------- #

  # These are "strict" insofar as they do not attempt to access thunks
  # or other auto-args.

  canPassStrict = fn: args: let
    fa = lib.functionArgs fn;
  in builtins.intersectAttrs fa args;

  canCallStrict = fn: args: ( missingArgsStrict args fn ) == {};


# ---------------------------------------------------------------------------- #

  # Taken from Nixpkgs' `lib.callPackageWith'.
  #
  # Given a function, and a list of extra recommendations ( for autoArgs ),
  # provide recommendations for correct spelling if the last argument `arg'
  # ( a string ) does not match an accepted argument name.
  #
  # funk -> [string] -> string -> [string]
  # fn   -> extra    -> arg    -> RETURN
  getSuggestionsStrict = fn: extra: arg: let
    fa    = removeAttrs ( lib.functionArgs fn ) extra;
    names = extra ++ ( builtins.attrNames fa );
    # Ignore distances greater than 2.
    # Stash distance for sorting later.
    suggest = acc: name: let
      value = lib.strings.levenshtein name arg;
    in if 2 < value then acc else acc ++ { inherit name value; };
    best   = builtins.foldl' suggest [] names;
    # Sort by distance, closest matches appear first.
    ranked = map ( x: x.name ) ( builtins.sort ( x: y: x.value < y.value ) );
  # Return best 3 matches, quoted.
  in map ( x: "\"${x}\"" ) ( lib.take 3 ranked );


  # Taken from Nixpkgs' `lib.callPackageWith'.
  prettySuggestions = fn: extra: arg: let
    suggestions = getSuggestionsStrict fn extra arg;
    body = lib.concatStringsSep ", " ( lib.init suggestions );
  in if suggestions == [] then "" else
     if lib.length suggestions == 1 then
        "did you mean ${builtins.head suggestions}?"
     else "did you mean ${body} or ${lib.last suggestions}?";


# ---------------------------------------------------------------------------- #
#
#  makeOverridable = f: origArgs:
#    let
#      result = f origArgs;
#
#      # Creates a functor with the same arguments as f
#      copyArgs = g: lib.setFunctionArgs g (lib.functionArgs f);
#      # Changes the original arguments with (potentially a function that returns) a set of new attributes
#      overrideWith = newArgs: origArgs // (if lib.isFunction newArgs then newArgs origArgs else newArgs);
#
#      # Re-call the function but with different arguments
#      overrideArgs = copyArgs (newArgs: makeOverridable f (overrideWith newArgs));
#      # Change the result of the function call by applying g to it
#      overrideResult = g: makeOverridable (copyArgs (args: g (f args))) origArgs;
#    in
#      if builtins.isAttrs result then
#        result // {
#          override = overrideArgs;
#          overrideDerivation = fdrv: overrideResult (x: overrideDerivation x fdrv);
#          ${if result ? overrideAttrs then "overrideAttrs" else null} = fdrv:
#            overrideResult (x: x.overrideAttrs fdrv);
#        }
#      else if lib.isFunction result then
#        # Transform the result into a functor while propagating its arguments
#        lib.setFunctionArgs result (lib.functionArgs result) // {
#          override = overrideArgs;
#        }
#      else result;
#

# ---------------------------------------------------------------------------- #

  # Shallow check, avoids fucking up a functor with wrappers.
  # This is pretty goofy honestly but it's a stub for any future references.
  arg_processor = let
    # arg0  = functor;
    # arg1  = ( yt.defun functor yt.any );
    # rsl   = yt.any;
    cond = ap: yt.function.check ( ap {} );
  in yt.restrict "arg_processor" cond yt.function;

  functor_with_processArgs = let
    cond = funk:
      ( funk ? __processArgs ) && ( funk ? __innerFunction ) &&
      ( yt.Funk.arg_processor.check funk.__processArgs );
  in yt.restrict "with_pargs" cond functor;

  hasStandardPAFunk = f:
    ( f ? __functor ) && ( f ? __processArgs ) && ( f ? __innerFunction ) &&
    ( f.__functionMeta.properties.funkT or null ) == "pargs-std";

  functor_with_std_processArgs =
    yt.restrict "std:pargs" hasStandardPAFunk functor;


# ---------------------------------------------------------------------------- #

  # Run arg processor on funk.
  # Throws an error if one isn't defined.
  processArgs = funk: ( functor_with_processArgs funk ).__processArgs funk;

  stdProcessArgsFunctor = self: x:
    self.__innerFunction ( self.__processArgs self x );

  # Strictly wrap a function with an argument handler/pre-processor.
  # NOTE: No `self' reference allowed during arg processing; the arg processor
  # is not a functor.
  #
  # Ex:
  # let incFloored = setFunctionArgProcess ( self: x: x + 1 ) builtins.floor;
  # in  map incFloored [1 1.1 1.9 2]
  # ==> [2 2 2 3]
  setFunctionArgProcessor = f: pa: {
    __functionMeta.properties.funkT = "pargs-std";
    __processArgs   = pa;
    __innerFunction = f;
    __functor       = stdProcessArgsFunctor;
  };


  # Write over existing `__processArgs' functor if one exists, operates under
  # the assumption that the functor is defined as the standard
  # `setFunctionProcessor' functor.
  setFunkArgProcessor = let
    inner = f: pa: { __functor = stdProcessArgsFunctor; } // f // {
      __functionMeta = ( f.__functionMeta or {} ) // {
        properties   = ( f.__functionMeta.properties or {} ) // {
          funkT = "pargs-std";
        };
      };
      __processArgs = pa;
    };
    nopa  = yt.restrict "no-pargs" ( f: ! ( f ? __processArgs ) ) functor;
    arg0  = yt.either functor_with_std_processArgs nopa;
  in yt.defun [arg0 arg_processor functor_with_processArgs] inner;

# ---------------------------------------------------------------------------- #

  defunk = {
    name           ? null
  , from           ? null
  , signature      ? null

  , meta           ? {}
  , __functionMeta ? meta

  , fargs ? null
  , __functionArgs ?
    fields.fargs or
    ( lib.functionArgs ( fields.__innerFunction or ( _: null ) ) )

  , pargs         ? null
  , __processArgs ? fields.pargs or
    ( self: x: let
      ta = ( self.__thunk or {} ) // x;
    in lib.canPassStrict self.__innerFunction ta )

  , fn              ? null
  , __innerFunction ? fields.fn or ( _: throw "defunk: fn undefined" )

  , funk      ? null
  , __functor ? fields.funk or stdProcessArgsFunctor
  , ...
  } @ fields: let
    clean = removeAttrs fields [
      "name" "from" "signature" "meta" "fargs" "pargs" "fn"
    ];
    fmaddFT =
      if fields ? __functor then {} else { properties.funkT = "pargs-std"; };
    fmAdd = fmaddFT // ( builtins.intersectAttrs {
      name = true; from = true; signature = true;
    } fields );
  in clean // {
    inherit __processArgs __functor __innerFunction __functionArgs;
    __functionMeta = lib.recursiveUpdate fmAdd __functionMeta;
  };


# ---------------------------------------------------------------------------- #

  setFunkMetaField = f: k: v: f // {
    __functionMeta = ( f.__functionMeta or {} ) // { ${k} = v; };
  };

  setFunkDoc  = f: setFunkMetaField "doc";
  setFunkProp = f: p: v: let
    prev = f.__functionMeta.properties or {};
  in setFunkMetaField "properties" ( prev // { ${p} = v; } );


# ---------------------------------------------------------------------------- #

  currySystems = supportedSystems: fn: args: let
    fas    = lib.functionArgs fn;
    callAs = system: fn ( { inherit system; } // args );
    callV  = system: fn system args;
    isSys  = ( builtins.isString args ) &&
             ( builtins.elem args supportedSystems );
    callF  = _: fn args;  # Flip
    apply  =
      if ( fas == {} ) then if isSys then callF else callV else
      if ( fas ? system ) then callAs else
      throw "provided function cannot accept system as an arg";
    sysAttrs = lib.eachSystemMap supportedSystems apply;
    curried  = { __functor = self: system: self.${system}; };
    curriedF = { __functor = self: self.${args}; };
  in sysAttrs // ( if isSys then curriedF else curried );

  curryDefaultSystems = currySystems lib.defaultSystems;


# ---------------------------------------------------------------------------- #

  # FIXME: rename this
  funkSystems = supportedSystems: fn: let
    fas    = lib.functionArgs fn;
    callAs = system: fn { inherit system; };
    apply  = if ( fas == {} ) then fn else if ( fas ? system ) then callAs
             else throw "provided function cannot accept system as an arg";
    sysAttrs = lib.eachSystemMap supportedSystems apply;
    curried  = { __functor = self: system: self.${system}; };
  in sysAttrs // curried;

  funkDefaultSystems = funkSystems lib.defaultSystems;


# ---------------------------------------------------------------------------- #

  # Apply a function to an attrset or potential args, automatically filtering
  # the set to those the function can accept.
  # NOTE: This is strictly meant to be used with functions that accept attrsets
  # as their argument, and is best suited for use with `setFunctionArgs'.
  #
  # lib.apply ( { x, y }: x + y ) { x = 1; y = 2; z = -1; }
  # => 3
  apply = x: args: let
    f = if lib.isFunction x then x else import x;
  in f ( builtins.intersectAttrs ( lib.functionArgs f ) args );


# ---------------------------------------------------------------------------- #

  # non-overridable form of `callPackageWith'.
  callWith = auto: x: let
    f = if lib.isFunction x then x else import x;
  in args:
     f ( ( builtins.intersectAttrs ( lib.functionArgs f ) auto ) // args );


# ---------------------------------------------------------------------------- #

  # Produce an overridable call to a function.
  # Return type must be an attrset.
  # An attribute called `override' is added to allow recall.
  callWithOvStrict = auto: x: let
    __innerFunction = if lib.isFunction x then x else import x;
    __thunk = builtins.intersectAttrs ( lib.functionArgs __innerFunction ) auto;
  in {
    inherit __innerFunction __thunk;
    __processArgs = self: args: self.__thunk // args;
    __functor = self: args: let
      result  = self.__innerFunction ( self.__processArgs self args );
    in assert builtins.isAttrs result;
       result // { override = self // { __thunk = self.__thunk // args; }; };
  };

  # Produce an overridable call to a function.
  # Return type need not be an attrset.
  # An attribute called `override' allows recall, and the return value of the
  # original call is stashed in `result'.
  callWithOvStash = auto: x: let
    __innerFunction = if lib.isFunction x then x else import x;
    __thunk = builtins.intersectAttrs ( lib.functionArgs __innerFunction ) auto;
  in {
    inherit __innerFunction __thunk;
    __processArgs = self: args: self.__thunk // args;
    __functor = self: args: {
      result   = self.__innerFunction ( self.__processArgs self args );
      override = self // { __thunk = self.__thunk // args; };
    };
  };

  # Produce an overridable call to a function.
  # If return type is an attrset, behave like `callWithOvStrict', otherwise
  # stash the returned value in `result' like `callWithOvStash'.
  callWithOv = auto: x: let
    __innerFunction = if lib.isFunction x then x else import x;
    __thunk = builtins.intersectAttrs ( lib.functionArgs __innerFunction ) auto;
  in {
    inherit __innerFunction __thunk;
    __processArgs = self: args: self.__thunk // args;
    __functor = self: args: let
      result   = self.__innerFunction ( self.__processArgs self args );
      override = self // { __thunk = self.__thunk // args; };
    in if builtins.isAttrs result then result // { inherit override; } else
       { inherit result override; };
  };


# ---------------------------------------------------------------------------- #

  # Create a Hoare triple from a functor that has a `__functionMeta.signature'
  # field, running pre/post conditions on input and output.
  # Limitations:
  #  - No curried functions.
  #    + Hoare triples are triples are tuples of "pre-condition predicate",
  #      "command", and "post-condition predicate".
  #    + Curried functions are more obnoxious to check in a standardized way
  #      especially if we want to avoid screwing up the functor's metadata
  #      fields as we curry.
  #  - Type signature must be expressed as a list of exactly two YANTS types.
  #    + "exactly two" is the consequence of "No curried functions".
  #  - The functor must account for `__processArgs' in relation to the declared
  #    type signature.
  #    + If `signature' indicates the argset before vs after `__processArgs',
  #      the functor needs to call the type checker at the proper time.
  mkFunkTypeChecker' = { __functionMeta, ... } @ functor: let
    argt = builtins.head __functionMeta.signature;
    rslt = builtins.elemAt __functionMeta.signature 1;
    name = __functionMeta.name or "<LAMBDA>";
    checkOne = type: v: let
      checked = type.checkType v;
      ok      = type.checkToBool checked;
      err'    = if ok then {} else { err = type.toError v checked; };
    in err' // { inherit type checked ok; };
    baseType = lib.libtypes.typedef' {
      inherit name;
      checkType = { args, result ? null }: let
        arg_info = checkOne argt args;
        rsl_info = checkOne rslt result;
      in {
        inherit arg_info rsl_info;
        ok = arg_info.ok && rsl_info.ok;
      };
      toError = { args, result }: { ok, arg_info, rsl_info }: let
        a   = arg_info; r = rsl_info;
        fl  = if ! ( __functionMeta ? from ) then ["("] else
              ["(" __functionMeta.from "."];
        loc = fl ++ [name "): "];
        msg = if ok then ["no errors."] else
              if a.ok then ["Typecheck of result failed:\n  ${r.err}"] else
              ["Typecheck of inputs failed:\n  ${a.err}"];
              #if r.ok then ["Typecheck of inputs failed:\n  ${a.err}"] else
              #["Typecheck of inputs and result failed.\n"
              # "Input Error:\n  ${a.err}\nResult Error:\n  ${r.err}\n"];
      in builtins.concatStringsSep "" ( loc ++ msg );
      def = { inherit argt rslt name checkOne; };
    };
  in baseType // {
    __toString = self: builtins.concatStringsSep "" [
      "TypeCheck[" name "] :: " argt.name " -> " rslt.name
    ];
  };

  mkFunkTypeChecker = yt.defun [yt.Typeclasses.functor yt.type]
                               mkFunkTypeChecker';


# ---------------------------------------------------------------------------- #

  funkName = funk: let
    from = funk.__functionMeta.from or null;
    name = funk.__functionMeta.name or "<LAMBDA>";
  in if from == null then name else
     if lib.test ".*#.+" from then "${from}.${name}" else  # Subattrs
     "${from}#${name}";                                    # Flake


# ---------------------------------------------------------------------------- #

in {

  inherit
    currySystems curryDefaultSystems
    funkSystems  funkDefaultSystems
  ;

  inherit
    mandatoryArgsStrict
    missingArgsStrict
    canPassStrict
    canCallStrict
    setFunctionArgProcessor
    apply
    callWith
    callWithOvStrict callWithOvStash callWithOv
  ;

  inherit
    processArgs
    stdProcessArgsFunctor
    hasStandardPAFunk
    setFunkArgProcessor
    setFunkMetaField
    setFunkProp
    setFunkDoc
    funkName
    defunk
  ;

  inherit
    mkFunkTypeChecker'
    mkFunkTypeChecker
  ;

  ytypes.Funk = {
    inherit arg_processor functor_with_processArgs functor_with_std_processArgs;
  };

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
