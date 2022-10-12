# ============================================================================ #
#
# Tests for `liblist' functions.
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  inherit (lib.liblist)
    takeUntil
    dropAfter
    dropUntil
    takeAfter
    commonPrefix
    commonSuffix
    mapNoNulls
    mapDropNulls
  ;

# ---------------------------------------------------------------------------- #

  tests = {

# ---------------------------------------------------------------------------- #

    testTakeUntil_0 = {
      expr     = takeUntil ( x: x == null ) [1 2 null 3];
      expected = [1 2];
    };

    testTakeUntil_1 = {
      expr     = takeUntil ( x: x == null ) [1 2 3];
      expected = [1 2 3];
    };


# ---------------------------------------------------------------------------- #

    testDropAfter_0 = {
      expr     = dropAfter ( x: x == null ) [1 2 null 3];
      expected = [1 2 null];
    };

    testDropAfter_1 = {
      expr     = dropAfter ( x: x == null ) [1 2 3];
      expected = [1 2 3];
    };


# ---------------------------------------------------------------------------- #

    testDropUntil_0 = {
      expr     = dropUntil ( x: x == null ) [1 2 null 3];
      expected = [null 3];
    };

    testDropUntil_1 = {
      expr     = dropUntil ( x: x == null ) [1 2 3];
      expected = [];
    };


# ---------------------------------------------------------------------------- #

    testTakeAfter_0 = {
      expr     = takeAfter ( x: x == null ) [1 2 null 3];
      expected = [3];
    };

    testTakeAfter_1 = {
      expr     = takeAfter ( x: x == null ) [1 2 3];
      expected = [];
    };


# ---------------------------------------------------------------------------- #

  };  # End tests


# ---------------------------------------------------------------------------- #

in lib.libdbg.mkTestHarness { name = "test-liblist"; inherit tests; }


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
