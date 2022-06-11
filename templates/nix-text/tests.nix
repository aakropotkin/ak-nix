{ lib       ? ( builtins.getFlake "github:aakropotkin/ak-nix/main?dir=lib" ).lib
, withDrv   ? false
, nixpkgs   ? builtins.getFlake "nixpkgs"
, system    ? builtins.currentSystem
, pkgs      ? nixpkgs.legacyPackages.${system}
, writeText ? pkgs.writeText
}:
let
  inherit (lib) libdbg libpath;

  harness = libdbg.mkTestHarness ( {
    env = { inherit lib system nixpkgs pkgs; };
    tests = with libpath; {

      testIsCoercibleToPath = {
        expr = map isCoercibleToPath ["" ./.];
        expected = [true true];
      };

    };
  } // ( if withDrv then { inherit writeText; } else {} ) );

in harness
