{
  description = "a basic package";

  inputs.utils.url = "github:numtide/flake-utils";
  inputs.utils.inputs.nixpkgs.follows = "/nixpkgs";

  inputs.basic-src.url   = "github:owner/basic";
  inputs.basic-src.flake = false;

  outputs = { self, nixpkgs, utils, basic-src }: let
    inherit (utils.lib) eachDefaultSystemMap;
  in {

    packages = eachDefaultSystemMap ( system: let
      pkgsFor = nixpkgs.legacyPackages.${system};
    in {
      basic = pkgsFor.stdenv.mkDerivation {
        pname = "basic";
        version = "0.0.0";
        src = basic-src;
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

      default = self.packages.${system}.basic;
    } );  # End Packages

  };
}
# NOTE: This approach to building is not compatible with overlays.
# This is fine for the vast majority of use cases, but if you need to add
# your package to the `nixpkgs.legacyPackages' set you'll need to write
# an overlay which references `nixpkgs' by `final' and `prev'.
# Cases where the overlay is useful are:
#   1. I want `stdenv' modifiers such as `pkgsCross' and `pkgsStatic' to work
#      on my package.
#   2. My package is a module for an interpreter, and I want it to be
#      available globally for functions like `mk<Lang>Package'.
#      This largely effects Python and Haskell.
