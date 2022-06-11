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
      withDrv   ? false
    , writeText ? null
    , tests
    , ...
    }@attrs:
      assert builtins.isAttrs tests; let
      attrs'      = removeAttrs attrs ["withDrv" "writeText"];
      run         = lib.runTests tests;
      check       = checker run;
      common      = { inherit run check; } // attrs';
      checkDrv    = checkerDrv writeText check;
      addCheckDrv = wt: common // { checkDrv = checkerDrv wt check; };
      drvExtras   = if withDrv then { inherit checkDrv; }
                               else { inherit addCheckDrv; };
    in common // drvExtras;


/* -------------------------------------------------------------------------- */

in {
  inherit report checker checkerDrv mkTestHarness;
} // lib.debug
