# ============================================================================ #
#
# General tests for `libsemver' routines.
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  inherit (builtins)
    compareVersions
  ;
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
    semverConstsEq
    semverConstRange
    semverConstExact
    semverConstTilde
    semverConstCaret
    semverConstGt
    semverConstGe
    semverConstLt
    semverConstLe

    semverConstAny
    semverConstFail

    semverConstAnd
    semverConstOr
    semverConstRangeEq
  ;


# ---------------------------------------------------------------------------- #

  tests = {

# ---------------------------------------------------------------------------- #

    testCompareVersions_0 = {
      expr     = compareVersions "0.0.1" "0.0.1";
      expected = 0;
    };

    testCompareVersions_1 = {
      expr     = compareVersions "0.0.1" "0.0.0";
      expected = 1;
    };

    testCompareVersions_2 = {
      expr     = compareVersions "0.0.0" "0.0.1";
      expected = -1;
    };

    testCompareVersions_3 = {
      expr     = compareVersions "0.0.0-a" "0.0.0-a";
      expected = 0;
    };

    # Any pre-release tag is considered "lower" than the same version untagged.
    testCompareVersions_4 = {
      expr     = compareVersions "0.0.0" "0.0.0-0";
      expected = -1;
    };

    # Version number still trumps with a pre-tag.
    testCompareVersions_5 = {
      expr     = compareVersions "0.0.1-0" "0.0.0";
      expected = 1;
    };

    testCompareVersions_6 = {
      expr     = compareVersions "0.0.0-0" "0.0.0-0";
      expected = 0;
    };

    # XXX: Pay attention here.
    # Pre-release tags are compared alphabetically, not numerically!
    # This means "x.y.z-0" > "x.y.z-1" which is not what you might expect.
    testCompareVersions_7 = {
      expr     = compareVersions "0.0.0-1" "0.0.0-0";
      expected = 1;
    };

    testCompareVersions_8 = {
      expr     = compareVersions "0.0.0-0" "0.0.0-1";
      expected = -1;
    };

    testCompareVersions_9 = {
      expr     = compareVersions "0.0.0-a" "0.0.0-b";
      expected = -1;
    };

    testCompareVersions_10 = {
      expr     = compareVersions "0.0.0-b" "0.0.0-a";
      expected = 1;
    };


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

    # Constraint typeclass basics

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

    testSemverConstRange_0 = {
      expr     = semverConstRange "1.0.0" "0.0.1" "0.5.0";
      expected = true;
    };

    testSemverConstExact_0 = {
      expr     = semverConstExact "1.0.0" "1.0.0";
      expected = true;
    };

    testSemverConstTilde_0 = {
      expr     = semverConstTilde "1.0.0" "1.0.0-pre";
      expected = true;
    };

    testSemverConstCaret_0 = {
      expr     = semverConstCaret "1.2.0" "1.3.0";
      expected = true;
    };

    testSemverConstGt_0 = {
      expr     = semverConstGt "1.2.0" "1.3.0";
      expected = true;
    };

    testSemverConstLt_0 = {
      expr     = semverConstLt "1.2.0" "1.3.0";
      expected = false;
    };

    testSemverConstAny_0 = {
      expr     = semverConstAny "1.2.0";
      expected = true;
    };

    testSemverConstFail_0 = {
      expr     = semverConstFail "1.2.0";
      expected = false;
    };


# ---------------------------------------------------------------------------- #

    testSemverConstAnd_0 = {
      #  1.0.0 < x < 1.0.2
      expr = ( semverConstAnd ( semverConstGt "1.0.0" )
                              ( semverConstLt "1.0.2" )
             ) "1.0.1";
      expected = true;
    };

    testSemverConstAnd_1 = {
      #  1.0.0 < x < 1.0.2
      expr = ( semverConstAnd ( semverConstGt "1.0.0" )
                              ( semverConstLt "1.0.2" )
             ) "1.0.3";
      expected = false;
    };

    testSemverConstAnd_2 = {
      # Ensure that we short circuit
      expr = ( semverConstAnd ( semverConstAny // { op = _: throw "FAIL"; } )
                              ( semverConstGt "1.0.0" )
             ) "1.0.1";
      expected = true;
    };

    testSemverConstAnd_3 = {
      # Ensure that we short circuit
      expr = ( semverConstAnd ( semverConstFail // { op = _: throw "FAIL"; } )
                              ( semverConstFail // { op = _: throw "FAIL"; } )
             ) "1.0.1";
      expected = false;
    };

    testSemverConstOr_0 = {
      # Ensure that we short circuit
      expr = ( semverConstOr ( semverConstGt "1.0.0" )
                             ( semverConstAny // { op = _: throw "FAIL"; } )
             ) "1.0.1";
      expected = true;
    };

    testSemverConstOr_1 = {
      # Ensure that we short circuit
      expr = ( semverConstOr ( semverConstAny // { op = _: throw "FAIL"; } )
                             ( semverConstAny // { op = _: throw "FAIL"; } )
             ) "1.0.1";
      expected = true;
    };

    testSemverConstOr_2 = {
      # Ensure that we short circuit
      expr = ( semverConstOr ( semverConstFail // { op = _: throw "FAIL"; } )
                             ( semverConstGt "1.0.0" )
             ) "1.0.1";
      expected = true;
    };


# ---------------------------------------------------------------------------- #

    testSemverConstRangeEq_0 = {
      expr = semverConstRangeEq ( semverConstRange "1.0.0" "1.1.0" )
                                ( semverConstRange "1.0.0" "1.1.0"  );
      expected = true;
    };

    testSemverConstRangeEq_1 = {
      expr = semverConstRangeEq ( semverConstRange "1.0.0" "1.1.0" )
                                ( semverConstRange "1.0.0" "1.1.1" );
      expected = false;
    };

    testSemverConstRangeEq_2 = {
      #  <= 1.1.0
      expr = semverConstRangeEq ( semverConstRange "1.0.0" "1.1.0" )
                                ( semverConstAnd ( semverConstGe "1.0.0" )
                                                 ( semverConstLe "1.1.0" ) );
      expected = true;
    };

    testSemverConstRangeEq_3 = {
      #  < 1.1.0
      expr = semverConstRangeEq ( semverConstRange "1.0.0" "1.1.0" )
                                ( semverConstAnd ( semverConstGe "1.0.0" )
                                                 ( semverConstLt "1.1.0" ) );
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
