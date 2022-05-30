{ lib   ? ( builtins.getFlake "nixpkgs" ).lib }:
rec {

  isAbspath = str: ( str != "" ) && ( builtins.substring 0 1 str ) == "/";
  asAbspath = path:
    let str = toString path; in
    if ( isAbspath str ) then str else ( ./. + ( "/" + str ) );


/* -------------------------------------------------------------------------- */

  realpathRel = from: to:
    let
      inherit (builtins) substring stringLength length split concatStringsSep;
      p = asAbspath from;
      s = asAbspath to;
      dropP = "." + ( substring ( stringLength p ) ( stringLength s ) s );
      isSub = ( stringLength p ) < ( stringLength s );
      swapped = realpathRel s p;
      dist = ( length ( split "/" swapped ) ) - 3;  # Ignore "./."
      dots = concatStringsSep "/" ( builtins.genList ( _: ".." ) dist );
    in if isSub then dropP else dots;


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
        filterDirs      = filterAttrs ( _: type: type == "directory" );
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
