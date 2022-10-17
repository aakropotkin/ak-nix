# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib       ? ( builtins.getFlake "github:NixOS/nixpkgs?dir=lib" ).lib
, nix       ? builtins.getFlake "github:NixOS/nix"
, yants-src ?
    builtins.fetchGit { url = "https://code.tvl.fyi/depot.git:/nix/yants.git"; }
#, exportDocs ? false
}: lib.extend ( import ./overlay.lib.nix )

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
