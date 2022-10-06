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

    testRangesOverlap_0 = {
      expr = semverRangesOverlap { from = "1.0.0"; to = "1.0.2"; }
                                 { from = "1.0.0"; to = "1.0.3"; };
      expected = true;
    };

    testRangesOverlap_1 = {
      expr = semverRangesOverlap { from = "1.0.0"; to = "1.0.2"; }
                                 { from = "1.0.1"; to = "1.0.3"; };
      expected = true;
    };

    testRangesOverlap_2 = {
      expr = semverRangesOverlap { from = "0.9.9"; to = "1.0.2"; }
                                 { from = "1.0.0"; to = "1.0.3"; };
      expected = true;
    };

    testRangesOverlap_3 = {
      expr = semverRangesOverlap { from = "1.0.0"; to = "1.0.4"; }
                                 { from = "1.0.1"; to = "1.0.3"; };
      expected = true;
    };

    testRangesOverlap_4 = {
      expr = semverRangesOverlap { from = "2.0.0"; to = "2.0.1"; }
                                 { from = "1.0.0"; to = "1.0.1"; };

      expected = false;
    };

    testRangesOverlap_5 = {
      expr = semverRangesOverlap { from = "1.0.0"; to = "1.0.1"; }
                                 { from = "2.0.0"; to = "2.0.1"; };
      expected = false;
    };

# ---------------------------------------------------------------------------- #

    testSemverSatExact_0 = {
      expr = semverSatExact "1.0.0" "1.0.0";
      expected = true;
    };

    testSemverSatExact_1 = {
      expr = semverSatExact "1.0.0" "2.0.0";
      expected = false;
    };


# ---------------------------------------------------------------------------- #

    testSemverSatTilde_0 = {
      expr = semverSatTilde "1.0.0" "1.0.0-0";
      expected = true;
    };

    testSemverSatTilde_1 = {
      expr = semverSatTilde "1.0.0" "1.0.0-pre";
      expected = true;
    };

    testSemverSatTilde_2 = {
      expr = semverSatTilde "1.0.0" "2.0.0-pre";
      expected = false;
    };


# ---------------------------------------------------------------------------- #

    testSemverSatCaret_0 = {
      expr = semverSatCaret "1.1.0" "1.0.0";
      expected = false;
    };

    testSemverSatCaret_1 = {
      expr = semverSatCaret "1.1.0" "1.1.0";
      expected = true;
    };

    testSemverSatCaret_2 = {
      expr = semverSatCaret "1.1.0" "1.2.0";
      expected = true;
    };

    testSemverSatCaret_3 = {
      expr = semverSatCaret "1.1.0" "2.0.0";
      expected = false;
    };


# ---------------------------------------------------------------------------- #

    testSemverConst_pred_0 = {
      expr = ( semverConst { op = "exact"; arg1 = "1.0.0"; } ) "1.0.0";
      expected = true;
    };

    testSemverConst_pred_1 = {
      expr = ( semverConst { op = "exact"; } ) "1.0.0" "1.0.1";
      expected = false;
    };

    testSemverConst_bin_0 = {
      expr = ( semverConst {
        op = "range";
        arg1 = { from = "1.0.0"; to = "1.1.0"; };
      } ) "1.0.1";
      expected = true;
    };

    testSemverConst_bin_1 = {
      expr = ( semverConst { op = "range"; } )
             { from = "1.0.0"; to = "1.1.0"; } "1.0.1";
      expected = true;
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
