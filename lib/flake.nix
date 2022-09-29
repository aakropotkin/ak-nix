{
  description = "Nixpkgs lib extension";

  inputs.nix.url = "github:NixOS/nix";
  inputs.nix.inputs.nixpkgs.follows = "/nixpkgs";

  inputs.yants-src = {
    type  = "file";
    url   = "https://code.tvl.fyi/plain/nix/yants/default.nix";
    flake = false;
  };
  
  outputs = { self, nixpkgs, nix, yants-src, ... }: {
    # An extension to `nixpkgs.lib'.
    lib = import ./. { inherit nix yants-src; inherit (nixpkgs) lib; };
  };
}
