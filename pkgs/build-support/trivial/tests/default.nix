{ lib       ? builtins.getFlake ( toString ../../../../lib )
, nixpkgs   ? builtins.getFlake "nixpkgs"
, system    ? builtins.currentSystem
, pkgs      ? nixpkgs.legacyPackages.${system}
, writeText ? pkgs.writeText
, gnutar    ? pkgs.gnutar
, gzip      ? pkgs.gzip
, tarutils  ? import ../tar.nix { inherit lib system gnutar gzip; }
, linkutils ? import ../link.nix { inherit lib system coreutils bash; }
, coreutils ? pkgs.coreutils
, bash      ? pkgs.bash
, runCommandNoCC ? pkgs.runCommandNoCC
, enableTraces   ? true
, ...
} @ args: let
  inputs = args // {
    inherit lib tarutils linkutils runCommandNoCC;
  };
  tests = import ./tests.nix {
    inherit lib runCommandNoCC linkutils tarutils;
  };
  run = lib.runTests tests;
  writeReport = test @ { name, expected, result }: let
    pass = expected == result;
    indentStr = "      ";
    indentBlock = lns:
      builtins.concatStringsSep "\n${indentStr}"
                                ( lib.splitString "\n" lns );
    msgFail = ''
      Test ${name} Failure: Expectation did not match result.
        expected:
          ---
            ${indentBlock expected}
          ---

        result:
          ---
            ${indentBlock result}
          ---
    '';
  in if pass then "Test ${name} Passes." else msgFail;
  log = builtins.concatStringsSep "\n" ( map writeReport run );
in writeText "trivial-tests" log
