{ lib     ? ( builtins.getFlake "nixpkgs" ).lib
, libstr  ? import ./strings.nix { inherit lib; }
, liblist ? import ./lists.nix { inherit lib; }
}:
rec {

/* -------------------------------------------------------------------------- */

  isAbspath = str: ( str != "" ) && ( builtins.substring 0 1 str ) == "/";
  asAbspath = path:
    let str = toString path; in
    if ( isAbspath str ) then str else ( ./. + ( "/" + str ) );


/* -------------------------------------------------------------------------- */

  commonParent = a: b:
    let
      inherit (builtins) split filter isString concatStringsSep;
      a' = filter isString ( split "/" ( asAbspath a ) );
      b' = filter isString ( split "/" ( asAbspath b ) );
      common = liblist.commonPrefix a' b';
    in if ( common == [] ) then "/" else ( concatStringsSep "/" common );


/* -------------------------------------------------------------------------- */

  # Get relative path between parent and subdir.
  # This will not work for non-subdirs.
  realpathRel' = from: to:
    let
      inherit (builtins) substring stringLength length split concatStringsSep;
      p = asAbspath from;
      s = asAbspath to;
      dropP = "." + ( substring ( stringLength p ) ( stringLength s ) s );
      isSub = ( stringLength p ) < ( stringLength s );
      swapped = realpathRel' s p;
      dist = libstr.count "/" swapped;
      dots = concatStringsSep "/" ( builtins.genList ( _: ".." ) dist );
    in if ( p == s ) then "." else if isSub then dropP else dots;

  # This handles non-subdirs.
  # WARNING: This function has no idea if your arguments are dirs or files!
  #          It will assume that they are directories.
  #          Also be mindful of how Nix may expand a Path ( type ) vs. a string.
  realpathRel = from: to:
    let
      parent = commonParent from to;
      fromToParent = realpathRel' from parent;
      parentToTo   = realpathRel' parent to;
      joined = "${fromToParent}/${parentToTo}";
      san = builtins.replaceStrings ["/./"] ["/"] joined;
      sanF = s: let m = builtins.match "(\\./)(.*)" s; in
                if ( m == null ) then s else ( builtins.elemAt m 1 );
      sanE = s: let m = builtins.match "(.*)(/\\.)" s; in
                if ( m == null ) then s else ( builtins.head m );
    in sanE ( sanF san );


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
