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
  file0 = builtins.toFile "file0.json" ( builtins.toJSON ( data0 ) );

  cont1 = ''
    {
      // Comment
      "a": 1,
      "b": ["hey", "there"],
      "c": {
        "d": null
      }
    }
  '';
  file1 = builtins.toFile "file1.json" cont1;


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
      expected = data0;
    };

    testImportJSONOr_1 = {
      expr     = importJSONOr data0 ( toString ./.fake-file.json );
      expected = data0;
    };


# ---------------------------------------------------------------------------- #

    testImportJSONOr'_0 = {
      expr     = importJSONOr' {} file1;
      expected = data0;
    };

    testImportJSONOr'_1 = {
      expr     = importJSONOr' data0 ( toString ./.fake-file.json );
      expected = data0;
    };


# ---------------------------------------------------------------------------- #

  };  # End tests


# ---------------------------------------------------------------------------- #

in lib.libdbg.mkTestHarness { name = "test-libjson"; inherit tests; }


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
