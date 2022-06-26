{
  description = "Nixpkgs lib extension";

  inputs.utils.url = "github:numtide/flake-utils/master";
  inputs.utils.inputs.nixpkgs.follows = "/nixpkgs";
  inputs.gitignore.url = "github:hercules-ci/gitignore.nix/master";
  inputs.gitignore.inputs.nixpkgs.follows = "/nixpkgs";
  
  # FIXME: Probably make this an output of `lib', and make `checks' outputs.
  outputs = { self, nixpkgs, utils, gitignore }:
    import ./. { inherit utils gitignore; inherit (nixpkgs) lib; };
}
