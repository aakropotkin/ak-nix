# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  genericFilt = name: type: let
    bname = baseNameOf name;
    ignoreDirs   = [".Trashes" ".direnv" ".git"];
    ignoreDirsP  = [];
    dirPred = let
      exact = builtins.elem bname ignoreDirs;
      match = builtins.any ( patt: lib.test patt bname ) ignoreDirsP;
    in assert type == "directory"; ! ( exact || match );
    ignoreFiles  = [
      "result" ".DS_Store" ".envrc" ".eslintcache" ".gitconfig" ".gitignore"
    ];
    ignoreFilesP = [".*~" "\\._.*" ".*\\.(tgz|tar(\\.gz)?)" "result-.*"];
    filePred = let
      exact = builtins.elem bname ignoreFiles;
      match = builtins.any ( patt: lib.test patt bname ) ignoreFilesP;
    in assert type != "directory"; ! ( exact || match );
  in if ( type == "directory" ) then dirPred else filePred;


# ---------------------------------------------------------------------------- #

  nixFilt' = name: type: let
    bname = baseNameOf name;
  in ( bname != "flake.lock" ) &&
     ( ! ( lib.test ".*\\.nix" name ) );

  nixFilt = name: type: ( genericFilt name type ) && ( nixFilt' name type );


# ---------------------------------------------------------------------------- #

in {
  inherit
    genericFilt
    nixFilt'
    nixFilt
  ;
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
