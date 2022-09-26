{
  description = "Nixpkgs lib extension";

  inputs.utils.url = "github:numtide/flake-utils/master";
  inputs.gitignore.url = "github:hercules-ci/gitignore.nix/master";
  inputs.gitignore.inputs.nixpkgs.follows = "/nixpkgs";
  inputs.nix.url = "github:NixOS/nix";
  inputs.nix.inputs.nixpkgs.follows = "/nixpkgs";
  
  outputs = { self, nixpkgs, utils, gitignore, nix, ... }: {
    lib = import ./. {
      inherit utils gitignore nix;
      inherit (nixpkgs) lib;
    };
  };
}
