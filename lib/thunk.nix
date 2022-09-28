# ============================================================================ #
#
# Essentially extensions and renames of Nixpkgs' `lib/customization.nix'.
# Largely this aims to use more "user friendly" names to make the use of
# things like `callPackageWith' and ``
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  # It's `makeOverridable' except you can customize the names.
  defFunkerWithNames = {
    genFnName          ? basename:
                        if settings == {} then basename
                                          else basename + "Custom"
  , override           ? "__override"
  , overrideDerivation ? "__overrideDrv"
  , thunk              ? "__thunk"
  , function           ? "__innerFunction"
  , functor            ? "__functor"
  , functionArgs       ? "__functionArgs"
  , functionMeta       ? "__functionMeta"
  , processArgs        ? "__processArgs"
  , mergeResult        ? true   # Merges result with "self"
                                # `false' stashes result in attr key `result'
  , result             ? "val"
  } @ settings: let  # -> autoArgs: fn: args:

# ---------------------------------------------------------------------------- #

    argMap = [
      { custom = override;           default = "override"; }
      { custom = overrideDerivation; default = "overrideDerivation"; }
      { custom = thunk;              default = "thunk"; }
      { custom = function;           default = "function"; }
      { custom = functor;            default = "functor"; }
      { custom = functionArgs;       default = "functionArgs"; }
      { custom = functionMeta;       default = "functionMeta"; }
      { custom = processArgs;        default = "processArgs"; }
    ];

    defaultToCustom = let
      proc = { custom, default }: { name = default; value = custom; };
    in builtins.listToAttrs ( map proc argMap );

    customToDefault = let
      proc = { custom, default }: { name = custom; value = default; };
    in builtins.listToAttrs ( map proc argMap );

    renameAsCustom = args: let
      asCustom = curr: value: {
        name = defaultToCustom.${curr} or curr;
        inherit value;
      };
      renamed = builtins.attrValues ( builtins.mapAttrs asCustom args );
    in builtins.listToAttrs renamed;

    renameAsDefault = args: let
      asDefault = curr: value: {
        name = customToDefault.${curr} or curr;
        inherit value;
      };
      renamed = builtins.attrValues ( builtins.mapAttrs asDefault args );
    in builtins.listToAttrs renamed;


# ---------------------------------------------------------------------------- #      

    defFnMeta' = {
      function     ? null
    , functor      ? null
    , functionArgs ?
        if meta ? processArgs then lib.functionArgs processArgs else
        if meta ? function then lib.functionArgs function else
        if meta ? functor  then lib.functionArgs functor  else
        {}
    , processArgs  ? x: x
    , argTypes     ? ["unspecified"] ++ ( lib.optional ( meta ? vargs ) "set" )
    , returnTypes  ? ["unspecified"]
    , argc         ? 1
    , vargs        ? false
    , name         ? "unspecified"
    , terminalArgs ? {}
    , ...
    } @ meta: let
      keepField = k: value:
        ( ! ( lib.hasPrefix "__" k ) ) &&
        ( ! ( builtins.elem k [
                "function" "functor" "functionArgs" "processArgs"
              ] ) );
    in {
      inherit argTypes returnTypes;
      terminalArgs = let
        mandatory = lib.filterAttrs ( _: optional: ! optional ) functionArgs;
        inferred  = if mandatory == {} then ["unspecified"] else
                    builtins.AttrNames mandatory;
      in meta.terminalArgs or inferred;
      keywords = let
        infers = {
          functor     = ( meta ? functor ) || ( meta ? processArgs );
          wrapper     = meta ? processArgs;
          polymorphic = 1 < ( builtins.length argTypes );
          thunk       = meta ? thunkMembers;
          vargs       = ( meta ? vargs ) && vargs;
          curried     = ( meta ? argc ) && ( 1 < argc );
          strict      = ( functionArgs != {} ) &&
                        ( builtins.all builtins.isBool
                                       ( builtins.attrValues functionArgs ) );
        };
        fallback = builtins.attrNames ( lib.filterAttrs ( _: c: c ) infers );
      in meta.keywords or fallback;
    } // ( lib.filterAttrs keepField meta );

    defFnMeta = {
      ${functionMeta} = {
        name         = genFnName "defFnMeta";
        argc         = 1;
        vargs        = true;
        argTypes     = ["set"];
        returnTypes  = ["function"];
      };
      ${functionArgs} = {
        ${function}     = true;
        ${functor}      = true;
        ${functionArgs} = true;
        ${processArgs}  = true;
        argTypes        = true;
        returnTypes     = true;
        argc            = true;
        vargs           = true;
        keywords        = true;
        name            = true;
        terminalArgs    = true;
      };
      ${function} = defFnMeta';
      ${processArgs} = self: renameAsDefault;
      __functor = self: args:
        self.${function} ( self.${processArgs} self args );
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

  in {
    ${defFnMeta.${functionMeta}.name} = defFnMeta;
    ${defFunkCore.${functionMeta}.name} = defFunkCore;
    ${defThunkedFunk'.${functionMeta}.name} = defThunkedFunk';
  };


# ---------------------------------------------------------------------------- #

  defaultFunker = defFunkerWithNames {};

# ---------------------------------------------------------------------------- #

in {

  inherit
    defFunkerWithNames
    defaultFunker
  ;

  inherit (defaultFunker)
    defFunkCore
    defFnMeta
  ;

}


# ---------------------------------------------------------------------------- #
#
#
# ============================================================================ #
