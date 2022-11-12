# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib       ? ( builtins.getFlake ( toString ../.. ) ).lib
, nixpkgs   ? builtins.getFlake "nixpkgs"
, system    ? builtins.currentSystem
, pkgs      ? nixpkgs.legacyPackages.${system}
, writeText ? pkgs.writeText
, ...
} @ args: let

  inherit (lib) libdbg libtriv;
  inherit (libtriv)
    sortVersions'
    sortVersions
  ;

# ---------------------------------------------------------------------------- #

  tests = {

    testSortVersions_0 = {
      expr     = sortVersions' { ascending = false; } ["1.0.0" "2.0" "3"];
      expected = ["3" "2.0" "1.0.0"];
    };

    testSortVersions_1 = {
      expr     = sortVersions' { ascending = true; } ["1.0.0" "2.0" "3"];
      expected = ["1.0.0" "2.0" "3"];
    };

    testSortVersions_3 = {
      expr = sortVersions' { accessor = baseNameOf; } [
        "foo/1.0.0" "bar/2.0.0" "baz/3.0.0"
      ];
      expected = ["baz/3.0.0" "bar/2.0.0" "foo/1.0.0"];
    };

  };  # End tests

in libdbg.mkTestHarness { name = "test-trivial"; inherit tests writeText; }


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
