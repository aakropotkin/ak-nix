# ============================================================================ #
#
# Provides sane defaults for running this set of tests.
# This is likely not the "ideal" way to utilize the test suite, but for someone
# who is consuming your project and knows nothing about it - this file should
# allow them to simply run `nix build -f .' to see if the test suite passes.
#
# ---------------------------------------------------------------------------- #

{ ak-nix    ? builtins.getFlake ( toString ../. )
, lib       ? ak-nix.lib
, system    ? builtins.currentSystem
, pkgsFor   ? ak-nix.legacyPackages.${system}
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
  autoArgs = {
    inherit lib pure ifd allowedPaths typecheck pkgsFor;
  } // args;

  tests = let
    testsFrom = file: let
      fn    = import file;
      fargs = builtins.functionArgs fn;
      ts    = fn ( builtins.intersectAttrs fargs autoArgs );
    in assert builtins.isAttrs ts;
       ts.tests or ts;
  in builtins.foldl' ( ts: file: ts // ( testsFrom file ) ) {} [
    ./libsemver.nix
    ./libfunk.nix
    ./libtag.nix
    ./libjson.nix
    ./liblist.nix
    ./attrsets.nix
    ./debug.nix
    ./strings.nix
    ./paths.nix
    ./encode.nix
    ./trivial.nix
  ];

# ---------------------------------------------------------------------------- #

  # We need `check' and `checkerDrv' to use different `checker' functions which
  # is why we have explicitly provided an alternative `check' as a part
  # of `mkCheckerDrv'.
  harness = let
    purity = if pure then "pure" else "impure";
    ne     = if nameExtra != "" then " " + nameExtra else "";
    name   = "ak-nix-${ne} (${system}, ${purity})";
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
