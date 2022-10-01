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
  ;


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

  };  # End Tests


# ---------------------------------------------------------------------------- #

in tests


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
