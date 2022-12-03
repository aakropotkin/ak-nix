# =========================================================================== #

# Test for your testers so we can test while we test!

{ lib }: let

  inherit (lib) libdbg;

# --------------------------------------------------------------------------- #

  # Tests for our tests.
  innerTests = {
    testMaths   = { expr = 1 + 1; expected = 2; };
    testStrings = { expr = builtins.substring 0 1 "foo"; expected = "f"; };
  };


# --------------------------------------------------------------------------- #

  tests = {

    # Sanity check the fields that `nixpkgs.lib.runTests' includes in its
    # list of failure cases.
    testRunTestsFields = {
      expr = let
        run    = lib.runTests { testFail = { expr = 1; expected = 2; }; };
        fields = builtins.attrNames ( builtins.head run );
      in fields;
      # The order of these matters, `attrNames' is alphabetically sorted.
      expected = ["expected" "name" "result"];
    };

    # Sanity check that `nixpkgs.lib.runTests' returns an empty list when all
    # tests pass.
    testRunner = {
      expr     = lib.runTests innerTests;
      expected = [];
    };

    # Sanity check that `libdbg.checker' returns `true' when all tests pass.
    testChecker = {
      expr     = libdbg.checkerDefault "tests" ( lib.runTests innerTests );
      expected = true;
    };

  };  # End tests


# --------------------------------------------------------------------------- #
in tests


# --------------------------------------------------------------------------- #
#
#
#
# =========================================================================== #
