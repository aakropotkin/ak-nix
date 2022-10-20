{
  description = "Nixpkgs lib extension";
  outputs = { nixpkgs, ... }: {
    lib = nixpkgs.lib.extend ( import ./overlay.lib.nix );
  };
}
