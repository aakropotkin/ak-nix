{
  description = "a small utility to create JSON objects";

  inputs.utils.url = github:numtide/flake-utils;

  outputs = { self, nixpkgs, utils }:
  let systemMap = utils.lib.eachSystemMap utils.lib.defaultSystems;
  in {
    packages = systemMap ( system:
      let pkgsFor = import nixpkgs { inherit system; };
      in rec {
        jo = pkgsFor.callPackage ./default.nix {};
        default = jo;
      }
    );
  };
}
