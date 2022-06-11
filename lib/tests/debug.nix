{ lib           ? ( builtins.getFlake ( toString ../.. ) ).lib
, nixpkgs       ? builtins.getFlake "nixpkgs"
, system        ? builtins.currentSystem
, pkgs          ? nixpkgs.legacyPackages.${system}
, writeText     ? pkgs.writeText
}:
let
  inherit (lib) libdbg;

/* -------------------------------------------------------------------------- */

  innerTests = {
    testMaths = { expr = 1 + 1; expected = 2; };
    testStrings = { expr = builtins.substring 0 1 "foo"; expected = "f"; };
  };


/* -------------------------------------------------------------------------- */

  tests = {

    testRunner = {
      expr     = lib.runTests innerTests;
      expected = [];
    };

    testRunTestsFields = {
      expr = let
        run = lib.runTests { testFail = { expr = 1; expected = 2; }; };
        fields = builtins.attrNames ( builtins.head run );
      in fields;
      expected = ["expected" "name" "result"];
    };

    testChecker = {
      expr = libdbg.checker "tests" ( lib.runTests innerTests );
      expected = true;
    };

  };


/* -------------------------------------------------------------------------- */

  harness = libdbg.mkTestHarness {
    inherit writeText tests;
    env = { inherit lib libdbg system nixpkgs pkgs tests innerTests; };
  };

in harness
