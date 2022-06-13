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

/* -------------------------------------------------------------------------- */

  data = {
    file1 = toFile "file1" ''
      foo
      bar
      baz
      quux
    '';
  };

  # Common test pattern for all `testYank*' cases.
  _mkYanker = e: f: map ( f "(.*[^a-z]+)?([a-z]+)([^a-z]+)" )
                        ( [" aa " "AaaAAA" "aa bb ZZ" "aa "] ++ e );
  mkYanker' = _mkYanker [];
  mkYanker  = _mkYanker ["A"];


/* -------------------------------------------------------------------------- */

  tests = {

    testTest = {
      expr = map ( test "[aA][bB]*" ) ["a" "A" "Ab" "aBBb" "x" "" "b" ".*"];
      expected = [true  true true true false false false false];
    };


/* -------------------------------------------------------------------------- */

    testYankN' = {
      expr = mkYanker' ( yankN' 1 );
      expected = ["aa" "aa" "bb" "aa"];
    };

    testYank' = {
      expr = mkYanker' yank';
      expected = [" " "A" "aa " null];
    };

    testYankNs' = {
      expr = mkYanker' ( yankNs' [0 1] );
      expected = [[" " "aa"] ["A" "aa"] ["aa " "bb"] [null "aa"]];
    };

    /* The safer ones */
    testYankN = {
      expr = mkYanker ( yankN 1 );
      expected = ["aa" "aa" "bb" "aa" null];
    };

    testYank = {
      expr = mkYanker yank;
      expected = [" " "A" "aa " null null];
    };

    testYankNs = {
      expr = mkYanker ( yankNs [0 1] );
      expected = [[" " "aa"] ["A" "aa"] ["aa " "bb"] [null "aa"] null];
    };


/* -------------------------------------------------------------------------- */



/* -------------------------------------------------------------------------- */


  }; /* End tests */


  harness = libdbg.mkTestHarness ( {
    inherit tests withDrv;
    name = "test-strings";
    inputs = args // { inherit lib libstr data; };
  } // ( if withDrv then { inherit writeText; } else {} ) );

in harness
