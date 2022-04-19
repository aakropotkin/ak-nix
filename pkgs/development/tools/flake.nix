{
  description = "a small utility to create JSON objects";

  inputs.utils.url = github:numtide/flake-utils;
  inputs.jq.url = {
    url = github:jpmens/jo;
    flake = false;
    rev = "6962bca178a6778328d1126ff762120305bb4327";
  };

  outputs = { self, nixpkgs, utils }:
  let systemMap = utils.lib.eachSystemMap utils.lib.defaultSystems;
  in {
    packages = systemMap ( system:
      let pkgsFor = import nixpkgs { inherit system; };
      in rec {
        jo = pkgsFor.stdenv.mkDerivation {
          pname = "jo";
          version = "1.6";
          nativeBuildInputs = [pkgsFor.autoreconfHook];
        };
        default = jo;
      }
    );
  };
}
