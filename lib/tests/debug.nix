{ lib           ? ( builtins.getFlake ( toString ../.. ) ).lib
, nixpkgs       ? builtins.getFlake "nixpkgs"
, system        ? builtins.currentSystem
, pkgs          ? nixpkgs.legacyPackages.${system}
, writeText     ? pkgs.writeText
}:
let
  inherit (lib) libdbg;

  tests = {
    testMaths = { expr = 1 + 1; expected = 2; };
    testStrings = { expr = builtins.substring 0 1 "foo"; expected = "f"; };
  };

  harness = libdbg.mkTestHarness {
    inherit writeText;
    env = { inherit lib libdbg system nixpkgs pkgs; };
    tests = with libdbg; {

      testChecker = {
        expr = checker "tests" ( lib.runTests tests );
        expected = true;
      }; 

    };
  };

in harness
