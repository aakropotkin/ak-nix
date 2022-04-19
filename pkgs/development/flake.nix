{
  description = "development packages";
  inputs.dev-tools.url = "path:./tools";
  outputs = { self, nixpkgs, dev-tools }: dev-tools.outputs;
}
