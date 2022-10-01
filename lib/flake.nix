{
  description = "Nixpkgs lib extension";

  inputs.nix.url = "github:NixOS/nix";
  inputs.nix.inputs.nixpkgs.follows = "/nixpkgs";

  inputs.yants-src = {
    url = "git+https://code.tvl.fyi/depot.git:/nix/yants.git";
    flake = false;
  };
  
  outputs = { self, nixpkgs, nix, yants-src, ... }: {
    # An extension to `nixpkgs.lib'.
    lib = import ./. { inherit nix yants-src; inherit (nixpkgs) lib; };
  };
}
