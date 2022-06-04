{ nixpkgs  ? builtins.getFlake "nixpkgs"
, system   ? builtins.currentSystem
, pkgs     ? import nixpkgs { inherit system; }
, texinfo  ? pkgs.texingo
}:
{
  texiToInfo = file: derivation {
      inherit system;
      name = builtins.replaceStrings ["texinfo" "texi"] ["info" "info"]
                                     file.name;
      builder = "${texinfo}/bin/makeinfo";
      args = ["-o" ( builtins.placeholder "out" ) file];
    };
}
