{ lib }:

let

  inherit (lib) runTests;  # From Nixpkgs

# ---------------------------------------------------------------------------- #

  # Given output from `nixpkgs.lib.runTests', use `trace' to print information
  # about failed test cases.
  report' = trace: { name, expected, result } @ test: let
    msg = ''
      Test ${name} Failure: Expectation did not match result.
        expected: ${lib.generators.toPretty {} expected}
        result:   ${lib.generators.toPretty {} result}
    '';
  in trace msg test;

  report = report' builtins.trace;


# ---------------------------------------------------------------------------- #

  # Tests are considered "passed" if `runner' returns an empty list, and I
  # recommend using `nixpkgs.lib.runTests' here.
  # I have left `runner' as an argument to allow users to provide a customized
  # test runtime.`
  # NOTE: `run' is a list of "evaluated" test cases which failed.
  #       They have the fields `{ name, expected, result }'.

  # Returns true/false
  checkerDefault = name: run:
    ( map ( t: ( t.result == t.expected ) || ( report t ) ) run ) == [];

  # Returns PASS/FAIL with test-suite name.
  checkerMsg = name: run:
    if run == [] then "PASS: ${name}" else "FAIL: ${name}";

  # Runs tests with tracing, ends in an assertion, return `true' if it survives.
  # This is the only checker where `doTrace' makes sense, because without it
  # the assertion can kill you before the user sees output.
  checkerEvalAssert' = doTrace: name: run: let
    rsl  = checkerDefault name run;
    msg  = checkerMsg name run;
    rsl' = if doTrace then builtins.deepSeq ( builtins.trace msg ) rsl else rsl;
  in assert rsl'; rsl';

  checkerEvalAssert = checkerEvalAssert' true;

  checkerReport = name: run: let
    # A phony runner used to capture report messages.
    msgs = [( checkerMsg name run )] ++ ( map ( report' ( x: _: x ) ) run );
    msg  = "  " + ( builtins.concatStringsSep "\n  " msgs );
    # The real runner.
    rsl  = checkerDefault name run;
  in if rsl then "PASS: ${name}" else "FAIL: ${name}" + msg;

  # Produce a dummy output if `check' succeeds.
  # I recommend passing the output of `checker' as the argument `check'.`
  # NOTE: This is largely here for reference, and as a nice starter.
  # You'll notice below in `mkTestHarness' I call `writeText' directly so that
  # I can change the name of the output file; but for the convenience of users
  # I've offered up this dinky wrapper.
  mkCheckerDrv = {
    name       ? "test"
  , keepFailed ? false
  , check
  , writeText
  }: ( writeText "${name}.log" check ).overrideAttrs ( _: _: {
    checkPhase = ''
      if grep -q "^FAIL: " "$out"; then
        cat "$out";
        cat "$out" >&2;
        ${lib.optionalString ( ! keepFailed ) "exit 1;"}
      fi
    '';
  } );


# ---------------------------------------------------------------------------- #

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
      name         ? "tests"
    , tests
    , runner       ? lib.runTests
    , run          ? runner tests
    , checker      ? checkerReport
    , check        ? checker name run
    , keepFailed   ? false
    , mkCheckerDrv ? lib.libdbg.mkCheckerDrv
    , writeText    ? throw "(mkTestHarnedd:${name}): You much provide writeText"
    , ...
    } @ args:
      assert builtins.isAttrs tests; let
      # Additional args get passed through to be members of output attrset.
      extraArgs = let
        needArgs = lib.functionArgs mkTestHarness;
      in removeAttrs args ( builtins.attrNames needArgs );
      # Minimum args needed by `mkCheckerDrv'
      args' = { inherit name check; } // args;
      mkCheckerDrv' = lib.callPackageWith args' mkCheckerDrv;
      # A functor that overrides itself, adding `writeText' to the callWith.
      # This allows you to inject it later in a call pipeline which can be
      # convenient for flakes.
      # If `writeText' was already given it's just the `checkDrv' call.`
      funk = if args ? writeText then {
        checkDrv = mkCheckerDrv' {};
        __functor  = self: mkCheckerDrv';
      } else {
        __functor = self: x: if builtins.isFunction x then self // {
          checkDrv = mkCheckerDrv' { writeText = x; };
          __functor = self: let
            nuargs = args' // { writeText = x; };
          in lib.makeCallPackagesWith nuargs mkCheckerDrv;
        } else mkCheckerDrv' x;
      };
    in extraArgs // { inherit name run check tests; } // funk;


# ---------------------------------------------------------------------------- #

in {
  inherit
    report'
    report
    checkerDefault
    checkerMsg
    checkerReport
    checkerEvalAssert'
    checkerEvalAssert
    mkCheckerDrv
    mkTestHarness
  ;
} // lib.debug
