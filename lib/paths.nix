{ lib }:
rec {

  isAbsolutePath = str: ( builtins.substring 0 1 str ) == "/";
  asAbspath = str:
    if ( isAbsolutePath str ) then str else ( ./. + ( "/" + str ) );


/* -------------------------------------------------------------------------- */

  extSuffix = path:
    let ms = builtins.match "^[^.].*\\.(.*)$" ( baseNameOf path );
    in if builtins.isNull ms then "" else builtins.head ms;


/* -------------------------------------------------------------------------- */

  /* This was taken from mkYarnPackage, and it works but isn't optimized. */

  /**
   * Path -> [PathGlobElem] -> [Path]
   * Note: Only directories are included, everything else is filtered out
   */
  expandGlobList = base: globElems:
    if globElems == [] then [base] else
      let
        inherit (builtins) head tail attrNames readDir filter match;
        inherit (lib) filterAttrs concatMap replaceStrings;
        globElemToRegex = replaceStrings ["*"] [".*"];
        elemRegex       = globElemToRegex ( head globElems );
        rest            = tail globElems;
        isDir           = filterAttrs ( _: type: type == "directory" )
        children        = attrNames ( filterDirs ( readDir base ) );
        childMatches    = child: ( match elemRegex child ) != null;
        chMatches       = filter childMatches children;
        chPath          = child: base + ( "/" + child );
      in concatMap ( ch: expandGlobList ( chPath ch ) rest ) chMatches;

  /**
   * Path -> PathGlob -> [Path]
   *
   * Ex:
   *   json-utils.expandGlob ../../../../foo "bar/baz/*"
   *     ==>
   *   [ /<ABS-PATH>/foo/bar/baz/quux /<ABS-PATH>/foo/bar/baz/sally ... ]
   */
  expandGlob = base: glob: expandGlobList base ( lib.splitString "/" glob );

}
