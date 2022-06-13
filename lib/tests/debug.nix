
# Test for your testers so we can test while we test!

{ lib       ? ( builtins.getFlake ( toString ../.. ) ).lib
, withDrv   ? false
, nixpkgs   ? builtins.getFlake "nixpkgs"
, system    ? builtins.currentSystem
, pkgs      ? nixpkgs.legacyPackages.${system}
, writeText ? pkgs.writeText
} @ args: let

  inherit (lib) libdbg;

/* -------------------------------------------------------------------------- */

  # Tests for our tests.
  innerTests = {
    testMaths = { expr = 1 + 1; expected = 2; };
    testStrings = { expr = builtins.substring 0 1 "foo"; expected = "f"; };
  };


/* -------------------------------------------------------------------------- */

  tests = {

    # Sanity check the fields that `nixpkgs.lib.runTests' includes in its
    # list of failure cases.
    testRunTestsFields = {
      expr = let
        run = lib.runTests { testFail = { expr = 1; expected = 2; }; };
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
      expr = libdbg.checker "tests" ( lib.runTests innerTests );
      expected = true;
    };

  };  # End tests


/* -------------------------------------------------------------------------- */

  # Use the test harness as our driver.
  # FIXME:
  # Honestly this should be a test case that is driven by a dead simple driver,
  # but I'm feeling lazy and this at leasts proves that `mkTestHarness'
  # is free of syntax errors and performs it's basic functions.
  #
  # The problem really being: if the test harness is broken in a way that
  # doesn't properly detect errors in tests, then it cannot be expected to
  # properly report its own flaws.
  # This is a "who polices the police?" paradox.
  harness = libdbg.mkTestHarness ( {
    inherit tests withDrv;
    name = "test-debug";
    inputs = args // { inherit lib libdbg tests innerTests; };
  } // ( if withDrv then { inherit writeText; } else {} ) );


/* -------------------------------------------------------------------------- */

in harness
