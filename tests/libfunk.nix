# ============================================================================ #
#
# General tests for `libfunk' routines.
#
# ---------------------------------------------------------------------------- #


{ lib }: let

# ---------------------------------------------------------------------------- #

  inherit (lib.libfunk)
    defFnMeta
    defFunkCore
    defThunkedFunk

    callWith
    currySystems
    funkSystems
    mandatoryArgsStrict
    missingArgsStrict
    canPassStrict
    canCallStrict
    setFunctionArgProcessor

    callWithOvStrict
    callWithOvStash
    callWithOv
  ;

  realAttrs = x: let
    top  = lib.filterAttrs ( k: v: ! ( lib.hasPrefix "__" k ) ) x;
    proc = k: v: if builtins.isAttrs v then realAttrs v else v;
  in builtins.mapAttrs proc top;


# ---------------------------------------------------------------------------- #

  tests = {

    inherit
      lib
      callWith
      currySystems
      funkSystems
      mandatoryArgsStrict
      missingArgsStrict
      canPassStrict
      canCallStrict
      setFunctionArgProcessor
    ;

# ---------------------------------------------------------------------------- #

    testFD_defFnMeta0 = {
      expr = defFnMeta {
        name        = "inc";
        argc        = 1;
        vargs       = false;
        argTypes    = ["int"];
        returnTypes = ["int"];
      };

      expected = {
        argTypes = ["int"];
        argc = 1;
        keywords = [];
        name = "inc";
        returnTypes = ["int"];
        vargs = false;
      };
    };


# ---------------------------------------------------------------------------- #

    testCallWithOvStrict_0 = {
      expr = let
        fn  = { x, y }: { val = x + y; };
        rsl = callWithOvStrict { z = 1; } fn { x = 2; y = 3; };
      in ( realAttrs rsl ) // { args = rsl.override.__thunk; };
      expected = { override = {}; val = 5; args = { x = 2; y = 3; }; };
    };

    testCallWithOvStrict_1 = {
      expr = let
        fn   = { x, y }: { val = x + y; };
        rsl0 = callWithOvStrict { z = 1; } fn { x = 2; y = 3; };
        rsl  = rsl0.override { x = 0; };
      in ( realAttrs rsl ) // { args = rsl.override.__thunk; };
      expected = { override = {}; val = 3; args = { x = 0; y = 3; }; };
    };


# ---------------------------------------------------------------------------- #

    testCallWithOvStash_0 = {
      expr = let
        fn  = { x, y }: x + y;
        rsl = callWithOvStash { z = 1; } fn { x = 2; y = 3; };
      in ( realAttrs rsl ) // { args = rsl.override.__thunk; };
      expected = { override = {}; result = 5; args = { x = 2; y = 3; }; };
    };

    testCallWithOvStash_1 = {
      expr = let
        fn   = { x, y }: x + y;
        rsl0 = callWithOvStash { z = 1; } fn { x = 2; y = 3; };
        rsl  = rsl0.override { x = 0; };
      in ( realAttrs rsl ) // { args = rsl.override.__thunk; };
      expected = { override = {}; result = 3; args = { x = 0; y = 3; }; };
    };

    testCallWithOvStash_2 = {
      expr = let
        fn   = { x, y }: { val = x + y; };
        rsl0 = callWithOvStash { z = 1; } fn { x = 2; y = 3; };
        rsl  = rsl0.override { x = 0; };
      in ( realAttrs rsl ) // { args = rsl.override.__thunk; };
      expected = { override = {}; result.val = 3; args = { x = 0; y = 3; }; };
    };


# ---------------------------------------------------------------------------- #

    testCallWithOv_0 = {
      expr = let
        fn  = { x, y }: x + y;
        rsl = callWithOv { z = 1; } fn { x = 2; y = 3; };
      in ( realAttrs rsl ) // { args = rsl.override.__thunk; };
      expected = { override = {}; result = 5; args = { x = 2; y = 3; }; };
    };

    testCallWithOv_1 = {
      expr = let
        fn   = { x, y }: x + y;
        rsl0 = callWithOv { z = 1; } fn { x = 2; y = 3; };
        rsl  = rsl0.override { x = 0; };
      in ( realAttrs rsl ) // { args = rsl.override.__thunk; };
      expected = { override = {}; result = 3; args = { x = 0; y = 3; }; };
    };

    testCallWithOv_2 = {
      expr = let
        fn   = { x, y }: { val = x + y; };
        rsl0 = callWithOv { z = 1; } fn { x = 2; y = 3; };
        rsl  = rsl0.override { x = 0; };
      in ( realAttrs rsl ) // { args = rsl.override.__thunk; };
      expected = { override = {}; val = 3; args = { x = 0; y = 3; }; };
    };


# ---------------------------------------------------------------------------- #

  };  # End Tests


# ---------------------------------------------------------------------------- #

in tests


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
