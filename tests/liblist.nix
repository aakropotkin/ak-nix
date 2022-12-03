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

    testCommonPrefix_0 = {
      expr     = commonPrefix [1 2 3] [1 2 4];
      expected = [1 2];
    };

    testCommonPrefix_1 = {
      expr     = commonPrefix [1 2 3] [3 2 1];
      expected = [];
    };


# ---------------------------------------------------------------------------- #

    testCommonSuffix_0 = {
      expr     = commonSuffix [1 2 3] [4 2 3];
      expected = [2 3];
    };

    testCommonSuffix_1 = {
      expr     = commonSuffix [1 2 3] [3 2 1];
      expected = [];
    };


# ---------------------------------------------------------------------------- #

    testMapNoNulls_0 = {
      expr     = mapNoNulls ( x: x + 1 ) [0 null 2];
      expected = [1 3];
    };

    testMapNoNulls_1 = {
      expr     = mapNoNulls ( x: null ) [0 null 2];
      expected = [null null];
    };


# ---------------------------------------------------------------------------- #

    testMapDropNulls_0 = {
      expr     = mapDropNulls ( x: if x != null then null else 0 ) [0 null 2];
      expected = [0];
    };

    testMapDropNulls_1 = {
      expr     = mapDropNulls ( x: null ) [0 null 2];
      expected = [];
    };


# ---------------------------------------------------------------------------- #

  };  # End tests


# ---------------------------------------------------------------------------- #

in tests


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
