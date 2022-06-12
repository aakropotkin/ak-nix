{
  description = "Nixpkgs lib extension";

  inputs.utils.url = "github:numtide/flake-utils/master";
  inputs.utils.inputs.nixpkgs.follows = "/nixpkgs";
  
  # FIXME: Probably make this an output of `lib', and make `checks' outputs.
  outputs = { self, nixpkgs, utils }:
    import ./. { inherit utils; inherit (nixpkgs) lib; };
}
