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
  in lib.intersectAttrs fa args;

  canCallStrict = fn: args: ( missingArgsStrict fn args ) == {};


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

  # Strictly wrap a function with an argument handler/pre-processor.
  # NOTE: No `self' reference allowed during arg processing; the arg processor
  # is not a functor.
  #
  # Ex:
  # let incFloored = setFunctionArgProcess ( x: x + 1 ) builtins.floor;
  # in  map incFloored [1 1.1 1.9 2]
  # ==> [2 2 2 3]
  setFunctionArgProcessor = f: pa: {
    __processArgs   = pa;
    __innerFunction = f;
    __functor = self: args: self.__innerFunction ( self.__processArgs args );
  };


# ---------------------------------------------------------------------------- #

  currySystems = supportedSystems: fn: args: let
    fas    = lib.functionArgs fn;
    callAs = system: fn ( { inherit system; } // args );
    callV  = system: fn system args;
    isSys  = ( builtins.isString args ) &&
             ( builtins.elem args supportedSystems );
    callF  = _: args': fn args args';  # Flip
    apply  =
      if ( fas == {} ) then if isSys then callF else callV else
      if ( fas ? system ) then callAs else
      throw "provided function cannot accept system as an arg";
    sysAttrs = lib.eachSystemMap supportedSystems apply;
    curried  = { __functor = self: system: self.${system}; };
    curriedF = { __functor = self: args': self.${args} args'; };
  in sysAttrs // ( if isSys then curriedF else curried );

  curryDefaultSystems = currySystems lib.defaultSystems;


# ---------------------------------------------------------------------------- #

  # FIXME: rename this
  funkSystems = supportedSystems: fn: let
    fas    = lib.functionArgs fn;
    callAs = system: fn { inherit system; };
    callV  = system: fn system;
    apply  = if ( fas == {} ) then callV else if ( fas ? system ) then callAs
             else throw "provided function cannot accept system as an arg";
    sysAttrs = lib.eachSystemMap supportedSystems apply;
    curried  = { __functor = self: system: self.${system}; };
  in sysAttrs // curried;

  funkDefaultSystems = funkSystems lib.defaultSystems;


# ---------------------------------------------------------------------------- #

  callWith = autoArgs: x: let
    f = if lib.isFunction x then x else import x;
  in f ( builtins.intersectAttrs ( lib.functionArgs f ) autoArgs );


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
    callWith
  ;

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
