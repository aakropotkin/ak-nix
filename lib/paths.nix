{ lib }:
let
  /* Taken from yarn2nix */
  globElemToRegex = builtins.replaceStrings ["*"] [".*"];

  # PathGlob -> [PathGlobElem]
  splitGlob = lib.splitString "/";

in rec {

  isAbsolutePath = str: ( builtins.substring 0 1 str ) == "/";
  asAbspath = str:
    if ( isAbsolutePath str ) then str else ( ./. + ( "/" + str ) );


/* -------------------------------------------------------------------------- */

  extSuffix = path: with builtins;
    let ms = match "^[^.].*\\.(.*)$" ( baseNameOf path );
    in if isNull ms then "" else head ms;


/* -------------------------------------------------------------------------- */


  # Path -> PathGlob -> [Path]
  expandGlob = base: glob: expandGlobList base ( splitGlob glob );

  /**
   * Path -> [PathGlobElem] -> [Path]
   * Note: Only directories are included, everything else is filtered out
   *
   * Ex:
   *   json-utils.expandGlob ../../../../environments "common/npm/*"
   *     ==>
   *   [ /<REPO-PATH>/environments/common/npm/accordion ... ]
   */
  expandGlobList = base: globElems:
    if globElems == [] then [base] else
      let
        inherit (builtins) head tail attrNames readDir filter match;
        inherit (lib) filterAttrs concatMap;
        elemRegex    = globElemToRegex ( head globElems );
        rest         = tail globElems;
        isDir        = filterAttrs ( _: type: type == "directory" )
        children     = attrNames ( filterDirs ( readDir base ) );
        childMatches = child: ( match elemRegex child ) != null;
        chMatches    = filter childMatches children;
        chPath       = child: base + ( "/" + child );
      in concatMap ( ch: expandGlobList ( chPath ch ) rest ) chMatches;

}
