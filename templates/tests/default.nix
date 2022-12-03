# ============================================================================ #
#
# Provides sane defaults for running this set of tests.
# This is likely not the "ideal" way to utilize the test suite, but for someone
# who is consuming your project and knows nothing about it - this file should
# allow them to simply run `nix build -f .' to see if the test suite passes.
#
# ---------------------------------------------------------------------------- #
#
# XXX: GETTING STARTED
#
# * Find/replace the string "PROJECT" with your project name.
#   The `bootstrap.sh' script should handle this for you, but in case you're
#   editing by hand that the first thing to change.
# * Move the `check.sh' script up to the root of your project ( or wherever your
#   flake lives ).
#   If you don't want it at the top level be sure to edit the `SDIR' or
#   `FLAKE_REF' env settings in the script to reflect the location.
# * Users should likely set the formal arg for `pkgsFor' based on their
#   flake setup to avoid complexity.
#   If your flake produces overlays or sets `legacyPackages' - then inline it!
# * If your tests are not sensitive to purity, "import from derivaiton" ( IFD ),
#   restricted reads ( `allowedPaths' ), or use any typecheckers - you can
#   remove the "Eval Env" formal arguments.
#   Having said that, if you create any derivations in your tests, you almost
#   certainly want to keep the `ifd' argument, since this can be used to block
#   tests from running on certain systems/platforms, or restricting
#   substitution of derivations from external binary caches/stores.
# * Probably add your tests to your flake's `checks' attrset.
#   Example:
#   ```
#     checks = at-node-nix.lib.eachDefaultSystemMap ( system: let
#       pkgsFor   = self.legacyPackages.${sysem};
#       testsWith = at-node-nix.lib.callWith pkgsFor ./tests;
#     in {
#       tests      = testsWith { typecheck = false; };
#       testsTyped = testsWith { nameExtra = "typed"; typecheck = true; };
#       testsFoo   = testsWith { nameExtra = "foo"; foo = true; };
#       # ...
#     };
#   ```
#   This will give you nice pretty traces with info from `pure' and `system',
#   and any additional tags you add to `nameExtra'.
# * Delete these instructions when you're done.
#
# ---------------------------------------------------------------------------- #

{ PROJECT   ? builtins.getFlake ( toString ../. )
, lib       ? PROJECT.lib
, system    ? builtins.currentSystem
, pkgsFor   ? let
    from = if PROJECT ? legacyPackages then PROJECT else PROJECT.inputs.nixpkgs;
    ov   = PROJECT.overlays.default or null;
    base = from.legacyPackages.${system};
  in if ov == null then base else base.extend ov;
, writeText ? pkgsFor.writeText

# Eval Env
, pure         ? lib.inPureEvalMode
, ifd          ? ( builtins.currentSystem or null ) == system
, allowedPaths ? toString ../.
, typecheck    ? true

# Options
, keepFailed ? false  # Useful if you run the test explicitly.
, nameExtra  ? ""
, ...
} @ args: let

# ---------------------------------------------------------------------------- #

  # Used to import test files.
  auto = { inherit lib pkgsFor writeText; } // args;

  tests = let
    testsFrom = file: let
      fn    = import file;
      fargs = builtins.functionArgs fn;
      ts    = fn ( builtins.intersectAttrs fargs auto );
    in assert builtins.isAttrs ts;
       ts.tests or ts;
  in builtins.foldl' ( ts: file: ts // ( testsFrom file ) ) {} [
    ./sub
  ];

# ---------------------------------------------------------------------------- #

  # We need `check' and `checkerDrv' to use different `checker' functions which
  # is why we have explicitly provided an alternative `check' as a part
  # of `mkCheckerDrv'.
  harness = let
    purity = if pure then "pure" else "impure";
    ne     = if nameExtra != "" then " " + nameExtra else "";
    name   = "PROJECT-tests${ne} (${system}, ${purity})";
  in lib.libdbg.mkTestHarness {
    inherit name keepFailed tests writeText;
    mkCheckerDrv = {
      __functionArgs  = lib.functionArgs lib.libdbg.mkCheckerDrv;
      __innerFunction = lib.libdbg.mkCheckerDrv;
      __processArgs   = self: args: self.__thunk // args;
      __thunk         = { inherit name keepFailed writeText; };
      __functor = self: x: self.__innerFunction ( self.__processArgs self x );
    };
    checker = name: run: let
      rsl = lib.libdbg.checkerReport name run;
      msg = builtins.trace rsl null;
    in builtins.deepSeq msg rsl;
  };


# ---------------------------------------------------------------------------- #

in harness


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
