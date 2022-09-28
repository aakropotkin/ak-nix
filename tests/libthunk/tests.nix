# ============================================================================ #
#
# General tests for `libthunk' routines.
#
# ---------------------------------------------------------------------------- #


{ lib }: let

# ---------------------------------------------------------------------------- #

  inherit (lib.libfunk)
    defFunkerWithNames

    defaultFunker
    defFunkCore
    defFnMeta

    defThunkedFunk'
  ;


# ---------------------------------------------------------------------------- #

  tests = {

    inherit
      lib
      defFunkerWithNames

      defaultFunker
      defFunkCore
      defFnMeta

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
        # FIXME:
        terminalArgs = ["unspecified"];
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
