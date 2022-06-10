{ lib }:

let

/* -------------------------------------------------------------------------- */

    report = { name, expected, result }: let
      msg = ''
        Test ${name} Failure: Expectation did not match result.
          expected: ${lib.libstr.coerceString expected}
          result:   ${lib.libstr.coerceString result}
      '';
    in builtins.trace msg false;


/* -------------------------------------------------------------------------- */

  # Runs tests with tracing, ends in an assertion.
    checker = runner: let
      ck = map ( t: ( t.result == t.expected ) || ( report t ) ) runner;
    in assert ( builtins.deepSeq ck ck ) == [];
      builtins.trace "PASS" ( ck == [] );


    checkerDrv = writeText: check:
      writeText "test.log" ( builtins.deepSeq check "PASS" );


/* -------------------------------------------------------------------------- */

    mkTestHarness = {
      writeText
    , tests
    , env   ? null
    , ...
    }@attrs:
      assert builtins.isAttrs tests; let
        run    = lib.runTests tests;
        check  = checker run;
      in {
        inherit run check;
        checkDrv = checkerDrv writeText check;
      } // attrs;


/* -------------------------------------------------------------------------- */

in {
  inherit report checker checkerDrv mkTestHarness;
} // lib.debug
