# ============================================================================ #
#
# Convert `texi' ( TexInfo ) files to `info' pages.
#
# ---------------------------------------------------------------------------- #

{ nixpkgs  ? builtins.getFlake "nixpkgs"
, system   ? builtins.currentSystem
, pkgs     ? import nixpkgs.legacyPackages.${system}
, texinfo  ? pkgs.texinfo
}: {
  texiToInfo = { name, ... } @ file: derivation {
    inherit system;
    name    = builtins.replaceStrings ["texinfo" "texi"] ["info" "info"] name;
    args    = ["-o" ( builtins.placeholder "out" ) file];
    builder = "${texinfo}/bin/makeinfo";
  };
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
