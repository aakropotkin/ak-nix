# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib
, untarSanPerms  ? pkgsFor.untarSanPerms
, runCommandNoCC ? pkgsFor.runCommandNoCC
, pkgsFor
}: let

  yt = lib.ytypes // lib.ytypes.Core // lib.ytypes.Prim;

# ---------------------------------------------------------------------------- #

  tests = {};

  drvs = {

    # Basic operation, tarball is already clean.
    testUntarSanPerms_0 = runCommandNoCC "test-unpack-safe" {
      untarred = untarSanPerms {
        name = "lodash-4.17.21";
        tarball = builtins.fetchTree {
          type    = "file";
          url     = "https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz";
          narHash = "sha256-fn2qMkL7ePPYQyW/x9nvDOl05BDrC7VsfvyfW0xkQyE=";
        };
      };
    } ''
      set -eu;
      set -o pipefail;
      for d in $( find "$untarred/" -type d -print; ); do
        if ! test -x "$d"; then
          echo "FAIL" >&2;
          stat "$d" >&2;
          exit 1;
        fi
      done
      echo "PASS" > "$out";
    '';

  };


# ---------------------------------------------------------------------------- #

in { inherit tests drvs; }

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
