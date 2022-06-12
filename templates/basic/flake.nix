{
  # FIXME: replace BASIC and OWNER with real info
  description = "a basic package";

  inputs.utils.url = "github:numtide/flake-utils";
  inputs.utils.inputs.nixpkgs.follows = "/nixpkgs";

  inputs.BASIC-src.url   = "github:OWNER/BASIC";
  inputs.BASIC-src.flake = false;

  outputs = { self, nixpkgs, utils, BASIC-src }: let
    inherit (utils.lib) eachDefaultSystemMap;
  in {

    packages = eachDefaultSystemMap ( system: let
      pkgsFor = nixpkgs.legacyPackages.${system};
    in {
      BASIC = pkgsFor.stdenv.mkDerivation {
        pname = "BASIC";
        version = "0.0.0";
        src = BASIC-src;
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

      default = self.packages.${system}.BASIC;
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
