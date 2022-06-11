{ lib       ? ( builtins.getFlake "github:aakropotkin/ak-nix/main?dir=lib" ).lib
, withDrv   ? false
, nixpkgs   ? builtins.getFlake "nixpkgs"
, system    ? builtins.currentSystem
, pkgs      ? nixpkgs.legacyPackages.${system}
, writeText ? pkgs.writeText
}:
let
  inherit (lib) libdbg;

  harness = libdbg.mkTestHarness ( {
    env = { inherit lib system nixpkgs pkgs; };
    tests = {

      testTrivial = {
        expr = let x = 0; in x;
        expected = 0;
      };

    };
    inherit withDrv;
  } // ( if withDrv then { inherit writeText; } else {} ) );

in harness
/**
 * Harness extends original arguments with `run', `check', and
 * ( maybe ) `checkDrv' with a `__functor' alias ( for `nix build'
 * to auto-call ).
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
