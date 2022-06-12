{ lib       ? ( builtins.getFlake ( toString ../.. ) ).lib
, withDrv   ? false
, nixpkgs   ? builtins.getFlake "nixpkgs"
, system    ? builtins.currentSystem
, pkgs      ? nixpkgs.legacyPackages.${system}
, writeText ? pkgs.writeText
, ...
} @ args: let

  inherit (builtins) typeOf tryEval mapAttrs attrNames attrValues toFile;
  inherit (lib.libstr)
    yankN' yank' yankNs' yankN yank yankNs
    coerceString
    charN count test
    commonPrefix commonSuffix
    matchingLines linesInfix readLines linesGrep readLinesGrep readGrep;

  inherit (lib) libdbg libstr;

  data = {
    file1 = toFile "file1" ''
      foo
      bar
      baz
      quux
    '';
  };

  tests = {

    testTest = {
      expr = map ( test "[aA][bB]*" ) ["a" "A" "Ab" "aBBb" "x" "" "b" ".*"];
      expected = [true  true true true false false false false];
    };

    testYankN' = {
      expr = map ( yankN' 1 "(.*[^a-z]+)?([a-z]+)([^a-z]+)" ) [
        " aa " "AaaAAA" "aa bb ZZ" "aa "
      ];
      expected = ["aa" "aa" "bb" "aa"];
    };

    testYank' = {
      expr = map ( yank' "(.*[^a-z]+)?([a-z]+)([^a-z]+)" ) [
        " aa " "AaaAAA" "aa bb ZZ" "aa "
      ];
      expected = [" " "A" "aa " null];
    };

    testYankNs' = {
      expr = map ( yankNs' [0 1] "(.*[^a-z]+)?([a-z]+)([^a-z]+)" ) [
        " aa " "AaaAAA" "aa bb ZZ" "aa "
      ];
      expected = [[" " "aa"] ["A" "aa"] ["aa " "bb"] [null "aa"]];
    };

  };

  harness = libdbg.mkTestHarness ( {
    inherit tests;
    inputs = args // { inherit lib libstr data; };
  } ) // ( if withDrv then { inherit writeText; } else {} );

in harness
