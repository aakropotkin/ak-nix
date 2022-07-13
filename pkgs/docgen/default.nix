{ nixpkgs ? builtins.getFlake "nixpkgs"
, system  ? builtins.currentSystem
, pkgs    ? nixpkgs.legacyPackages.${system}
, pandoc  ? pkgs.pandoc
, texinfo ? pkgs.texinfo
, ...
}:
let
  pandocGen     = import ./pandoc { inherit pandoc; };
  infoGen       = import ./makeinfo { inherit texinfo; };
  moduleOptions = import ./module-options.nix {
    inherit pandocGen infoGen pkgs nixpkgs;
    inherit (pkgs) linkFarmFromDrvs;
  };
  # NOTE: This is only "okay" because these imports do not clash on any
  #       fields that are attribute (sub)sets.
  #       If you ever add `meta' to `makeinfo/default.nix' you need to fix this.
in pandocGen // infoGen // moduleOptions
