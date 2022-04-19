{
  description = "a basic package";

  inputs.utils.url = github:numtide/flake-utils;
  inputs.@PROJECT@-src.url = {
    url = github:@OWNER@/@PROJECT@;
    flake = false;
  };

  outputs = { self, nixpkgs, utils, @PROJECT@-src }:
  let systemMap = utils.lib.eachSystemMap utils.lib.defaultSystems;
  in {
    packages = systemMap ( system:
      let pkgsFor = import nixpkgs { inherit system; };
      in rec {
        @PROJECT@ = pkgsFor.stdenv.mkDerivation {
          pname = "@PROJECT@";
          version = "@VERSION@";
          src = @PROJECT@-src;
          nativeBuildInputs = with pkgsFor; [
            # pkg-config
            # help2man
            # texinfoInteractive
            autoreconfHook
          ];
          buildInputs = with pkgsFor; [
            # zlib.dev
          ];
        };
        default = @PROJECT@;
      }
    );
  };
}

