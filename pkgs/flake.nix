{
  description = "packages";
  inputs.development.url = "path:./development";
  outputs = { self, nixpkgs, development }: development.outputs;
}
