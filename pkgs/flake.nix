{
  description = "packages";
  inputs.pkgs.url = "path:./development";
  outputs = { self, nixpkgs, development }: development.outputs;
}
