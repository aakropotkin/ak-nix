{
  description = "development tools packages";
  inputs.jo.url = "path:./jo";
  outputs = { self, nixpkgs, jo }: jo.outputs;
}
