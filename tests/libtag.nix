# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib } @ args: let

  inherit (lib.libtag)
    verifyTag
    tagName
    tagValue
    discr
    discrDef
    match
    matchLam
    matchTag
  ;

# ---------------------------------------------------------------------------- #

  tests = {

# ---------------------------------------------------------------------------- #

    testVerifyTag_0 = {
      expr     = ( verifyTag { foo = 1; } ).isTag;
      expected = true;
    };

    testVerifyTag_1 = {
      expr     = ( verifyTag { foo = 1; bar = 0; } ).isTag;
      expected = false;
    };

    testTagName = {
      expr     = tagName { foo = 1; };
      expected = "foo";
    };

    testTagValue = {
      expr     = tagValue { foo = 1; };
      expected = 1;
    };


# ---------------------------------------------------------------------------- #

    testDiscrDef_0 = {
      expr = discrDef "smol" [
        { biggerFive = i: i > 5; }
        { negative = i: i < 0; }
      ] ( -100 );
      expected = { negative = -100; };
    };

    testDiscrDef_1 = {
      expr = discrDef "smol" [
        { biggerFive = i: i > 5; }
        { negative = i: i < 0; }
      ] 1;
      expected = { smol = 1; };
    };


# ---------------------------------------------------------------------------- #

    testDiscr_0 = {
      expr = builtins.tryEval ( discr [
        { biggerFive = i: i > 5; }
        { negative   = i: i < 0; }
      ] ( -100 ) );
      expected = { success = true; value.negative = -100; };
    };

    testDiscr_1 = {
      expr = builtins.tryEval ( discr [
        { biggerFive = i: i > 5; }
        { negative   = i: i < 0; }
      ] 1 );
      expected = { success = false; value = false; };
    };


# ---------------------------------------------------------------------------- #

    testMatchTag = let
      matcher = {
        res = i: i + 1;
        err = _: 0;
      };
    in {
      expr = {
        success = matchTag { res = 42; } matcher;
        failure = matchTag { err = "no answer"; } matcher;
      };
      expected = {
        success  = 43;
        failure = 0;
      };
    };


# ---------------------------------------------------------------------------- #

    testMatchLam = {
      expr = lib.pipe { foo = 42; } [
        ( matchLam {
            foo = i: if i < 23 then { small = i; } else { big = i; };
            bar = _: { small = 5; };
          } )
        ( matchLam {
            small = i: "yay it was small";
            big = i: "whoo it was big!";
          }  )
      ];
      expected = "whoo it was big!";
    };


# ---------------------------------------------------------------------------- #

  };  # End tests


# ---------------------------------------------------------------------------- #

in lib.libdbg.mkTestHarness { name = "test-libtag"; inherit tests; }


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
