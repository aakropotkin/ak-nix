{
  description = "a basic autotools package";

  inputs.utils.url = github:numtide/flake-utils;

  outputs = { self, nixpkgs, utils, @PROJECT@-src }:
  let systemMap = utils.lib.eachSystemMap utils.lib.defaultSystems;
  in {
    packages = systemMap ( system:
      let pkgsFor = import nixpkgs { inherit system; };
      in rec {
        @PROJECT@ = pkgsFor.callPackage ./default.nix {};
        default = @PROJECT@;
      }
    );
    defaultPackage = systemMap ( system: self.package.${system}.default );
  };
}

