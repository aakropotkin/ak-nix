# ============================================================================ #

{ lib       ? ( builtins.getFlake ( toString ../.. ) ).lib
, nixpkgs   ? builtins.getFlake "nixpkgs"
, system    ? builtins.currentSystem
, pkgs      ? nixpkgs.legacyPackages.${system}
, writeText ? pkgs.writeText
, ...
} @ args: let

  inherit (lib) libdbg libpath;

# ---------------------------------------------------------------------------- #

  tests = with libpath; {

    testIsCoercibleToPath = {
      expr = builtins.mapAttrs ( _: isCoercibleToPath ) {
        emptyString = "";
        dot         = ".";
        pwdPath     = ./.;
        setOutPath  = { outPath = ""; };
      };
      expected = {
        emptyString = false;
        dot         = true;
        pwdPath     = true;
        setOutPath  = true;
      };
    };

    testExtSuffix = {
      expr = extSuffix "foo.bar.baz";
      expected = "bar.baz";
    };

    testExtSuffix' = {
      expr = extSuffix' "foo.bar.baz";
      expected = "baz";
    };

    testDropLeadingDotSlash = {
      expr = map dropLeadingDotSlash [
        "./foo" ".bar" "/baz" "quux/." "sally" "/"
      ];
      expected = ["foo" ".bar" "/baz" "quux/." "sally" "/"];
    };

    testStripComponents = {
      expr =
        ( map ( stripComponents 1 ) [
          "./foo" "bar" "foo/bar" ( /. + "foo/bar/" )
        ] ) ++ ( map ( stripComponents 2 ) [
          "./foo" "bar" "foo/bar" ( /. + "foo/bar/" ) "foo/bar/baz/quux"
          "/foo/bar//baz" "foo/bar//baz"
        ] );
      expected = [
        "foo" "bar" "bar" "foo/bar"
        "foo" "bar" "bar" "bar" "baz/quux"
        "bar//baz" "baz"
      ];
    };

    # FIXME: need to make example dir
    # TODO: check the "symlinkdir" works.
    #testCategorizePath = {
    #  expr = map categorizePath [];
    #  expected = [];
    #};

  };  # End tests

in libdbg.mkTestHarness { name = "test-paths"; inherit tests writeText; }


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
