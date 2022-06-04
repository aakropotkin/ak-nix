{ nixpkgs  ? builtins.getFlake "nixpkgs"
, system   ? builtins.currentSystem
, pkgs     ? import nixpkgs { inherit system; }
, pandoc   ? pkgs.pandoc
, texinfo  ? pkgs.texinfo
, ...
}:
let
  pandocGen = import ./pandoc { inherit pandoc; };
  infoGen   = import ./makeinfo { inherit texinfo; };
  # NOTE: This is only "okay" because these imports do not clash on any
  #       fields that are attribute (sub)sets.
  #       If you ever add `meta' to `makeinfo/default.nix' you need to fix this.
in pandocGen // infoGen
