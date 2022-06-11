{ lib       ? ( builtins.getFlake ( toString ../.. ) ).lib
, withDrv   ? false
, nixpkgs   ? builtins.getFlake "nixpkgs"
, system    ? builtins.currentSystem
, pkgs      ? nixpkgs.legacyPackages.${system}
, writeText ? pkgs.writeText
}@args:
let
  inherit (lib) libdbg libpath;

  harness = libdbg.mkTestHarness ( {
    env = ( removeAttrs args ["withDrv" "writeText"] ) // { inherit lib; };
    tests = with libpath; {

      testIsCoercibleToPath = {
        expr = map isCoercibleToPath ["" ./.];
        expected = [true true];
      };

    };
  } // ( if withDrv then { inherit writeText; } else {} ) );

in harness
