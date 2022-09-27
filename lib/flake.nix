{
  description = "Nixpkgs lib extension";

  inputs.nix.url = "github:NixOS/nix";
  inputs.nix.inputs.nixpkgs.follows = "/nixpkgs";
  
  outputs = { self, nixpkgs, nix, ... }: {
    lib = import ./. {
      inherit nix;
      inherit (nixpkgs) lib;
    };
  };
}
