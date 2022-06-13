{ lib }:

let

/* -------------------------------------------------------------------------- */

  # Given output from `nixpkgs.lib.runTests', use `trace' to print information
  # about failed test cases.
  report = test @ { name, expected, result }: let
    msg = ''
      Test ${name} Failure: Expectation did not match result.
        expected: ${lib.libstr.coerceString expected}
        result:   ${lib.libstr.coerceString result}
    '';
  in builtins.trace msg test;


/* -------------------------------------------------------------------------- */

  # Runs tests with tracing, ends in an assertion.
  # Tests are considered "passed" if `runner' returns an empty list, and I
  # recommend using `nixpkgs.lib.runTests' here.
  # I have left `runner' as an argument to allow users to provide a customized
  # test runtime.`
  checker = name: runner: let
    ck = map ( t: ( t.result == t.expected ) || ( report t ) ) runner;
    rsl = ck == [];
    msg = if rsl then "PASS: ${name}" else "FAIL: ${name}";
    rsl' = builtins.deepSeq ( builtins.trace msg ) rsl;
  in assert rsl'; rsl';


  # Produce a dummy output if `check' succeeds.
  # I recommend passing the output of `checker' as the argument `check'.`
  # NOTE: This is largely here for reference, and as a nice starter.
  # You'll notice below in `mkTestHarness' I call `writeText' directly so that
  # I can change the name of the output file; but for the convenience of users
  # I've offered up this dinky wrapper.
  checkerDrv = writeText: check:
    writeText "test.log" check;


/* -------------------------------------------------------------------------- */

  /**
   * `mkTestHarness' extends original arguments with `run', `check', and
   * ( maybe ) `checkDrv' with a `__functor' alias ( for `nix build'
   * to auto-call ).
   * The use case for this is in a `flake.nix' or `default.nix' where you want
   * to handle batches of `tests.nix' style files with attrsets of tests with
   * a general purpose harness.
   * A preferable approach is to use the template `ak-nix.templates.nix-tests'
   * which provides more purpose built files for specific use cases such as
   * `nix repl', `nix eval', and `nix build'; but `mkTestHarness' is nice for
   * when you're feeling lazy.
   *
   * `run' simply evaluates `test' case pairs using `lib.runTests'
   * returning a list of test cases where `expr' did not match `expected'.
   * This is "really" the function you'll want to use for interactive
   * development, and notably it does NOT require any Nixpkgs references.
   * If you really just want `run' you can pass in `withDrv = false' and/or
   * remove `writeText' from your test file entirely.
   * Later on if you want to add the `checkDrv' you can use
   * `harness' = harness.addCheckDrv pkgs.writeText;' to make it
   * available lazily ( I recommend this approach for tests which are
   * purely Nix expressions with no dependencies outside of `lib' ).
   *
   * `check' invokes `run' and forces deep-evaluation, printing `trace'
   * output and uses `assert' to enforce that all tests MUST pass.
   * This is intended for use with a CI system or `nix flake check', where
   * you really just want an exit status of 0/1 for a set of tests.
   * This is not a particularly useful function for iterative development,
   * for which I recommend using `run' directly.
   *
   * Finally you've got `checkDrv' which simply runs `check' and writes a
   * dummy derivation output when they succeed.
   * This just exists so you can call `nix build -f ./tests.nix' or add
   * Nix expressions checks to CI/Hydra jobs.
   * Again, not particularly useful for interactive dev.
   */
    mkTestHarness = {
      withDrv   ? ( writeText != null )
    , writeText ? null
    , name      ? "tests"
    , tests
    , ...
    }@attrs:
      assert builtins.isAttrs tests; let
      attrs'      = removeAttrs attrs ["withDrv" "writeText"];
      run         = lib.runTests tests;
      check       = checker name run;
      common      = { inherit run check; } // attrs';
      checkDrv    = writeText "${name}.log" check;
      __functor   = self: self.checkDrv;
      addCheckDrv = wt: common // {
        checkDrv = writeText "${name}.log" check;
        inherit __functor;
      };
      drvExtras   = if withDrv then { inherit checkDrv __functor; }
                               else { inherit addCheckDrv; };
    in common // drvExtras;


/* -------------------------------------------------------------------------- */

in {
  inherit report checker checkerDrv mkTestHarness;
} // lib.debug
