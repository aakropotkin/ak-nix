# ============================================================================ #
#
# Tests for `libjson' functions.
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  inherit (lib.libjson)
    importJSON'
    importJSONOr
    importJSONOr'
  ;

# ---------------------------------------------------------------------------- #

  data0 = { a = 1; b = ["hey" "there"]; c = { d = null; }; };
  file0 = ./data/file0.json;
  file1 = ./data/file1.json;


# ---------------------------------------------------------------------------- #

  tests = {

# ---------------------------------------------------------------------------- #

    testImportJSON'_0 = {
      expr     = importJSON' file0;
      expected = data0;
    };

    testImportJSON'_1 = {
      expr     = importJSON' file1;
      expected = data0;
    };


# ---------------------------------------------------------------------------- #

    testImportJSONOr_0 = {
      expr     = importJSONOr {} file0;
      expected = if lib.inPureEvalMode then {} else data0;
    };

    testImportJSONOr_1 = {
      expr     = importJSONOr data0 ./.fake-file.json;
      expected = data0;
    };


# ---------------------------------------------------------------------------- #

    testImportJSONOr'_0 = {
      expr     = importJSONOr' {} file1;
      expected = if lib.inPureEvalMode then {} else data0;
    };

    testImportJSONOr'_1 = {
      expr     = importJSONOr' data0 ./.fake-file.json;
      expected = data0;
    };


# ---------------------------------------------------------------------------- #

  };  # End tests


# ---------------------------------------------------------------------------- #

in tests


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
