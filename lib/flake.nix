{
  description = "Nixpkgs lib extension";

  inputs.nix.url = "github:NixOS/nix";
  inputs.nix.inputs.nixpkgs.follows = "/nixpkgs";

  outputs = { nixpkgs, nix, ... }: {
    # An extension to `nixpkgs.lib'.
    lib = import ./. { inherit nix; inherit (nixpkgs) lib; };
  };
}
