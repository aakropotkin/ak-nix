# ============================================================================ #
#
# Essentially extensions and renames of Nixpkgs' `lib/customization.nix'.
# Largely this aims to use more "user friendly" names to make the use of
# things like `callPackageWith' and ``
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  defFnMeta = {
    __functionMeta = {
      name         = "defFnMeta";
      argc         = 1;
      vargs        = true;
      argTypes     = ["set"];
      returnTypes  = ["function"];
    };
    __functionArgs = {
      name            = true;
      argc            = true;
      vargs           = true;
      argTypes        = true;
      returnTypes     = true;
      keywords        = true;
      terminalArgs    = true;
    };
    __functor = self: self.__innerFunction;
    __innerFunction = meta: {
      keywords = let
        infers = {
          #functor     = ( meta ? functor ) || ( meta ? __processArgs );
          #wrapper     = meta ? __processArgs;
          #polymorphic = 1 < ( builtins.length meta.argTypes );
          thunk       = meta ? thunkMembers;
          vargs       = ( meta ? vargs ) && meta.vargs;
          curried     = ( meta ? argc ) && ( 1 < meta.argc );
          #strict      = ( meta.__functionArgs != {} ) &&
          #              ( builtins.all builtins.isBool
          #                  ( builtins.attrValues meta.__functionArgs ) );
        };
        fallback = builtins.attrNames ( lib.filterAttrs ( _: c: c ) infers );
      in meta.keywords or fallback;
    } // meta;
  };


# ---------------------------------------------------------------------------- #
    
  defFunkCore = {
    __functionMeta = {
      name         = "defFunkCore";
      argc         = 1;
      vargs        = false;
      argTypes     = ["set"];
      returnTypes  = ["function"];
    };
    __functionArgs = {
      __innerFunction = true;
      __functor       = true;
      __functionArgs  = true;
      __functionMeta  = true;
      __processArgs   = true;
    };
    __functor = self: args: let
      margs = builtins.intersectAttrs {
        __function     = true;
        __functor      = true;
        __functionArgs = true;
        __processArgs  = true;
      } args;
      targs = if ! ( self ? __processArgs ) then args else
              self.__processArgs self args;
    in self.__innerFunction ( targs // {
      __functionMeta = defFnMeta margs;
    } );
  };


# ---------------------------------------------------------------------------- #

  defThunkedFunk = {
    __functionMeta = {
      name         = "defThunkedFunk";
      argc         = 1;
      vargs        = false;
      argTypes     = ["set"];
      returnTypes  = ["function"];
    };
    __functionArgs = {
      __thunk            = true;  # ? {}
      __innerFunction    = true;  # ? functor ; NO `processArgs'
      __processArgs      = true;  # ? Merge thunk with args
      __functor          = true;  # ? pargs -> makeOverridable
      __functionMeta     = true;  # ? {}
      override           = true;  # ? `makeOverrideable' field
      overrideDerivation = true;  # ? `makeOverrideable' field
    };
    __functor = self: self.__innerFunction self;
    __innerFunction = args: let
      core = defFunkCore args;
    in lib.recursiveUpdate core {
      __functionMeta.thunkMembers =
        args.__functionMeta or
        ( builtins.attrNames ( args.__thunk or {} ) );
      __thunk = args.__thunk or {};
    };
  };


# ---------------------------------------------------------------------------- #

in {

  inherit
    defFnMeta
    defFunkCore
    defThunkedFunk
  ;

}


# ---------------------------------------------------------------------------- #
#
#
# ============================================================================ #
