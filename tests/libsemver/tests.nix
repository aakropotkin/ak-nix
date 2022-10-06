# ============================================================================ #
#
# General tests for `libsemver' routines.
#
# ---------------------------------------------------------------------------- #


{ lib }: let

# ---------------------------------------------------------------------------- #

  inherit (lib.libsemver)
    semverRange
    semverInRange
    semverJoinRanges'
    semverIntersectRanges'
    semverRangesOverlap
  ;
  inherit (lib.libsemver)
    semverSatRange
    semverSatExact
    semverSatTilde
    semverSatCaret
    semverSatGt
    semverSatGe
    semverSatLt
    semverSatLe
    semverSatAnd
    semverSatOr
    semverSatAny
    semverSatFail
  ;
  inherit (lib.libsemver)
    semverConst
  ;


# ---------------------------------------------------------------------------- #



# ---------------------------------------------------------------------------- #

  tests = {

# ---------------------------------------------------------------------------- #

    testSemverRange_0 = {
      expr     = semverRange { from = "1.0.0"; to = "0.0.1"; };
      expected = { from = "0.0.1"; to = "1.0.0"; };
    };

    testSemverRange_1 = {
      expr     = semverRange "1.0.0" "0.0.1";
      expected = { from = "0.0.1"; to = "1.0.0"; };
    };

    testSemverRange_2 = {
      expr     = semverRange "0.0.0" "0.0.0";
      expected = { from = "0.0.0"; to = "0.0.0"; };
    };

    testSemverRange_3 = {
      expr     = semverRange { from = "0.0.1"; to = "0.0.2"; };
      expected = { from = "0.0.1"; to = "0.0.2"; };
    };


# ---------------------------------------------------------------------------- #

    testSemverInRange_0 = {
      expr     = semverInRange { from = "1.0.0"; to = "1.0.2"; } "1.0.1";
      expected = true;
    };

    testSemverInRange_1 = {
      expr     = semverInRange { from = "1.0.0"; to = "1.0.2"; } "1.0.0";
      expected = true;
    };

    testSemverInRange_2 = {
      expr     = semverInRange { from = "1.0.0"; to = "1.0.2"; } "1.0.2";
      expected = true;
    };

    testSemverInRange_3 = {
      expr     = semverInRange { from = "1.0.0"; to = "1.0.2"; } "1.0.3";
      expected = false;
    };

    testSemverInRange_4 = {
      expr     = semverInRange { from = "1.0.0"; to = "1.0.2"; } "0.1.0";
      expected = false;
    };


# ---------------------------------------------------------------------------- #

    testJoinRanges_0 = {
      expr = semverJoinRanges' { from = "1.0.0"; to = "1.0.2"; }
                               { from = "1.0.0"; to = "1.0.3"; };
      expected = { from = "1.0.0"; to = "1.0.3"; };
    };

    testJoinRanges_1 = {
      expr = semverJoinRanges' { from = "1.0.0"; to = "1.0.2"; }
                               { from = "1.0.1"; to = "1.0.3"; };
      expected = { from = "1.0.0"; to = "1.0.3"; };
    };

    testJoinRanges_2 = {
      expr = semverJoinRanges' { from = "0.9.9"; to = "1.0.2"; }
                               { from = "1.0.0"; to = "1.0.3"; };
      expected = { from = "0.9.9"; to = "1.0.3"; };
    };

    testJoinRanges_3 = {
      expr = semverJoinRanges' { from = "1.0.0"; to = "1.0.4"; }
                               { from = "1.0.1"; to = "1.0.3"; };
      expected = { from = "1.0.0"; to = "1.0.4"; };
    };

    testJoinRanges_4 = {
      expr = semverJoinRanges' { from = "1.0.1"; to = "1.0.3"; }
                               { from = "1.0.0"; to = "1.0.4"; };
      expected = { from = "1.0.0"; to = "1.0.4"; };
    };


# ---------------------------------------------------------------------------- #

    testIntersectRanges_0 = {
      expr = semverIntersectRanges' { from = "1.0.0"; to = "1.0.2"; }
                                    { from = "1.0.0"; to = "1.0.3"; };
      expected = { from = "1.0.0"; to = "1.0.2"; };
    };

    testIntersectRanges_1 = {
      expr = semverIntersectRanges' { from = "1.0.0"; to = "1.0.2"; }
                                    { from = "1.0.1"; to = "1.0.3"; };
      expected = { from = "1.0.1"; to = "1.0.2"; };
    };

    testIntersectRanges_2 = {
      expr = semverIntersectRanges' { from = "0.9.9"; to = "1.0.2"; }
                                    { from = "1.0.0"; to = "1.0.3"; };
      expected = { from = "1.0.0"; to = "1.0.2"; };
    };

    testIntersectRanges_3 = {
      expr = semverIntersectRanges' { from = "1.0.0"; to = "1.0.4"; }
                                    { from = "1.0.1"; to = "1.0.3"; };
      expected = { from = "1.0.1"; to = "1.0.3"; };
    };

    testIntersectRanges_4 = {
      expr = semverIntersectRanges' { from = "1.0.1"; to = "1.0.3"; }
                                    { from = "1.0.0"; to = "1.0.4"; };
      expected = { from = "1.0.1"; to = "1.0.3"; };
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
