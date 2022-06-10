{
  description = "Nixpkgs lib extension";

  inputs.utils.url = "github:numtide/flake-utils/master";
  inputs.utils.inputs.nixpkgs.follows = "/nixpkgs";
  
  outputs = { self, nixpkgs, utils }:
    import ./. { inherit utils; inherit (nixpkgs) lib; };
}
