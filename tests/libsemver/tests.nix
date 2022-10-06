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

  };  # End Tests


# ---------------------------------------------------------------------------- #

in tests


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
