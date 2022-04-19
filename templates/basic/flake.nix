{
  description = "a basic package";

  inputs.utils.url = github:numtide/flake-utils;
  inputs.@PROJECT@.url = {
    url = github:@OWNER@/@PROJECT@;
    flake = false;
  };

  outputs = { self, nixpkgs, utils }:
  let systemMap = utils.lib.eachSystemMap utils.lib.defaultSystems;
  in {
    packages = systemMap ( system:
      let pkgsFor = import nixpkgs { inherit system; };
      in rec {
        @PROJECT@ = pkgsFor.stdenv.mkDerivation {
          pname = "@PROJECT@";
          version = "@VERSION@";
          nativeBuildInputs = [pkgsFor.autoreconfHook];
        };
        default = @PROJECT@;
      }
    );
  };
}

