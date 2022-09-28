# ============================================================================ #
#
# Essentially extensions and renames of Nixpkgs' `lib/customization.nix'.
# Largely this aims to use more "user friendly" names to make the use of
# things like `callPackageWith' and ``
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  defFnMeta = let
    #defFnMeta' = {
    #  argTypes     ? ["unspecified"] ++ ( lib.optional ( meta ? vargs ) "set" )
    #, returnTypes  ? ["unspecified"]
    #, argc         ? 1
    #, vargs        ? false  # Only include for fns that accept a set
    #, name         ? "unspecified"
    #, terminalArgs ? {}
    #, ...
    #} @ meta: {
    #  inherit argTypes returnTypes;
    #};
    terminalArgs = let
      mandatory = lib.filterAttrs ( _: optional: ! optional ) __functionArgs;
      inferred  = if mandatory == {} then ["unspecified"] else
                  builtins.AttrNames mandatory;
    in meta.terminalArgs or inferred;
    keywords = let
      infers = {
        #functor     = ( meta ? functor ) || ( meta ? processArgs );
        #wrapper     = meta ? processArgs;
        polymorphic = 1 < ( builtins.length argTypes );
        thunk       = meta ? thunkMembers;
        vargs       = ( meta ? vargs ) && vargs;
        curried     = ( meta ? argc ) && ( 1 < argc );
        #strict      = ( functionArgs != {} ) &&
        #              ( builtins.all builtins.isBool
        #                             ( builtins.attrValues functionArgs ) );
      };
      fallback = builtins.attrNames ( lib.filterAttrs ( _: c: c ) infers );
    in meta.keywords or fallback;
  in {
    __functionMeta = {
      name         = genFnName "defFnMeta";
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
    __innerFunction = FIXME;
    __functor = self: args:
      self.__innerFunction ( self.__processArgs self args );
  };


# ---------------------------------------------------------------------------- #
    
  defFunkCore = {
    ${functionMeta} = {
      name         = genFnName "defFunkCore";
      argc         = 1;
      vargs        = false;
      argTypes     = ["set"];
      returnTypes  = ["function"];
    };
    ${functionArgs} = {
      ${function}     = true;
      ${functor}      = true;
      ${functionArgs} = true;
      ${functionMeta} = true;
      ${processArgs}  = true;
    };
    __functor = self: args: let
      dargs = renameAsDefault args;
      margs = builtins.intersectAttrs {
        function     = true;
        functor      = true;
        functionArgs = true;
        processArgs  = true;
      } dargs;
    in ( if functor == "__functor" then {
      __functor = self: args: let
        targs = if ! ( self ? ${processArgs} ) then args else
                self.${processArgs} self args;
      in self.${function} targs;
    } else {
      ${functor} = functor;
      __functor  = self: self.${functor} self;
    } ) // {
      ${functionMeta} = defFnMeta margs;
    };
  };


# ---------------------------------------------------------------------------- #

  defThunkedFunk' = {
    ${functionMeta} = {
      name         = genFnName "defThunkedFunk";
      argc         = 1;
      vargs        = false;
      argTypes     = ["set"];
      returnTypes  = ["function"];
    };
    ${functionArgs} = {
      ${thunk}              = true;  # ? {}
      ${function}           = true;  # ? functor ; NO `processArgs'
      ${processArgs}        = true;  # ? Merge thunk with args
      ${functor}            = true;  # ? pargs -> makeOverridable
      ${functionMeta}       = true;  # ? {}
      ${override}           = true;  # ? `makeOverrideable' field
      ${overrideDerivation} = true;  # ? `makeOverrideable' field
    };

    ${function} = args: let
      core = defFunkCore args;
    in lib.recursiveUpdate core {
      ${functionMeta}.thunkMembers =
        args.${functionMeta} or
        ( builtins.attrNames ( args.${thunk} or {} ) );
      ${thunk} = args.${thunk} or {};
    };
    # FIXME:
    ${processArgs} = self: renameAsDefault;
    __functor = self: args:
      self.${function} ( self.${processArgs} self args );
  };


# ---------------------------------------------------------------------------- #

in {

  inherit
    defFnMeta
  ;

}


# ---------------------------------------------------------------------------- #
#
#
# ============================================================================ #
