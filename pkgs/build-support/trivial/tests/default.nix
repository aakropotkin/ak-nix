{ lib            ? builtins.getFlake ( toString ../../../../lib )
, writeText      ? pkgs.writeText
, runCommandNoCC ? pkgs.runCommandNoCC
, tarutils       ? import ../tar.nix { inherit lib system gnutar gzip; }
, linkutils      ? import ../link.nix { inherit lib system coreutils bash; }

# Optional: Only required if attrs aboves attempt to fallback.
, nixpkgs        ? builtins.getFlake "nixpkgs"
, system         ? builtins.currentSystem
, pkgs           ? nixpkgs.legacyPackages.${system}
, gnutar         ? pkgs.gnutar
, gzip           ? pkgs.gzip
, coreutils      ? pkgs.coreutils
, bash           ? pkgs.bash

# Configurables:
# --------------
# When using `writeRunReport', Print the report to `stderr' as well.
# This has no effect on other outputs.
, enableTraces ? true

# Applied to the output out `printTestReport' for traced output.
# If you change this just be sure you match the original function prototype.
, traceFn ? builtins.trace

# Change the output. This is most useful for importing `tests.nix' into the REPL
# or a `nix eval --expr' call to avoid pulling inputs explicitly.
# The following two examples are equivalent, but they illustrate the utility:
#
#   nix-repl> tests = ( import ./default.nix { outputAttr = "tests"; } )
#   nix-repl> :lf nixpkgs
#   nix-repl> :p lib.runTests tests
#
#   nix-repl> :p import ./default.nix { outputAttr = "run"; }
#
# You can also export `outputs' in its entirety using `outputAttrs = "all";'.
# NOTE: Yes, I implemented a lock-less flake from scratch - I'm aware.
, outputAttr ? "writeRunReport"

# You can set this to a list of test names to limit what gets run.
, testsToRun ? null

# You can pass in whatever else you want, it'll be added to `inputs', which
# is really only useful for the REPL.
, ...
} @ args: let


/* -------------------------------------------------------------------------- */

  inputs = args // {
    inherit lib nixpkgs system pkgs;
    inherit tarutils linkutils;
    inherit runCommandNoCC writeText gzip coreutils bash;
    inherit testsToRun;
  };

  tests = ( import ./tests.nix {
    inherit lib runCommandNoCC linkutils tarutils;
  } ) // ( if testsToRun == null then {} else { tests = testsToRun; } );

  run = lib.runTests tests;


/* -------------------------------------------------------------------------- */

  printTestReport = test @ { name, expected, result }: let
    pass = expected == result;
    indentStr = "      ";
    indentBlock = lns:
      builtins.concatStringsSep "\n${indentStr}"
                                ( lib.splitString "\n" lns );
    msgFail = ''
      Test ${name} Failure: Expectation did not match result.
        expected:
          ---
            ${indentBlock ( lib.libstr.coerceString expected )}
          ---

        result:
          ---
            ${indentBlock ( lib.libstr.coerceString result )}
          ---
    '';
  in if pass then "Test ${name} Passes." else msgFail;

  printRunReport = builtins.concatStringsSep "\n" ( map printTestReport run );

  # Print the report to `stderr', and return the outputs of `runTests'.
  traceRunReport = traceFn printRunReport run;

  # Create a derivation from the report.
  writeRunReport = let
    reporter = if enableTraces then printRunReport
                               else traceFn printRunReport printRunReport;
  in writeText "trivial-tests" printRunReport;


/* -------------------------------------------------------------------------- */

  outputs = {
    inherit inputs tests run traceFn;
    inherit printTestReport printRunReport writeRunReport traceRunReport;
  };

  output = if outputAttr == "all" then outputs else outputs.${outputAttr};


/* -------------------------------------------------------------------------- */

in output
