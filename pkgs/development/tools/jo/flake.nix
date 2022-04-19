{
  description = "a small utility to create JSON objects";

  inputs.utils.url = github:numtide/flake-utils;
  inputs.jo-src = {
    url = github:jpmens/jo?rev=6962bca178a6778328d1126ff762120305bb4327;
    flake = false;
  };

  outputs = { self, nixpkgs, utils, jo-src }:
  let systemMap = utils.lib.eachSystemMap utils.lib.defaultSystems;
  in {
    packages = systemMap ( system:
      let pkgsFor = import nixpkgs { inherit system; };
      in rec {
        jo = pkgsFor.stdenv.mkDerivation {
          pname = "jo";
          version = "1.6";
          src = jo-src;
          nativeBuildInputs = with pkgsFor; [
            pkg-config
            pandoc
            autoreconfHook
          ];
        };
        default = jo;
      }
    );
  };
}
