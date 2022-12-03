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
# * Read the instructions in [[file:../default.nix]], and basically do the same
#   stuff here.
#   The only real difference is to relative path for `PROJECT'
#   and `allowedPaths'.
#
# ---------------------------------------------------------------------------- #

{ PROJECT   ? builtins.getFlake ( toString ../../. )
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
, allowedPaths ? toString ../../.
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
    ./tests.nix
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
