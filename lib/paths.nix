{ lib }:
let
  inherit (builtins) isString typeOf;
  inherit (builtins) readDir isPath pathExists;

/* -------------------------------------------------------------------------- */

  __doc__isCoercibleToPath = ''(Pred) Can `x' be coerced to a Path?'';
  isCoercibleToPath = x:
    ( isPath x ) || ( isString x ) || ( lib.isDerivation x );


  __doc__coercePath = ''Force a path-like `x' to be a Path.'';
  coercePath = x:
    if isPath x then x else
    if lib.isDerivation x then x.outPath else
    if ( ! isString x ) then
      throw "Cannot coerce a path from type: ${typeOf x}" else
    if isAbspath x then ( /. + x ) else ( ./. + "/${x}" );


/* -------------------------------------------------------------------------- */

  __doc__isAbspath = ''
    (Pred) Is path-like `x' an absolute path?
    This is always true for Path types, but we're really interested in checking
    for whether or not a relative path-like (string) needs to be resolved.
  '';
  isAbspath = x:
    if isPath x then true else if ( ! isString x ) then
    throw "Cannot get absolute path of type: ${typeOf x}" else
    ( x != "" ) && ( builtins.substring 0 1 x ) == "/";


  __doc__asAbspath = ''Resolve a relative path to an absolute path.'';
  asAbspath = path: let
    str = toString path;
  in if ( isAbspath str ) then str else ( ./. + ( "/" + str ) );


/* -------------------------------------------------------------------------- */

  __doc__categorizePath = ''
    Return inode type for path-like `x', being one of "directory", "regular",
    "symlink", or "unknown" ( for sockets and other oddities ).
    Path-like `x' must exist, and is processed by `coercePath', allowing strings
    and relative paths to be used.
  '';
  categorizePath = x: let
    p = coercePath x;
  in assert isCoercibleToPath x;
     assert pathExists p;
     ( readDir ( dirOf p ) ).${baseNameOf p};


/* -------------------------------------------------------------------------- */

  __doc__commonParent = ''
    Return the nearest common parent directory for path-likes `a' and `b'.
    This will eventually fall back to "/" if needed.
    Common parent is detected by path splitting alone - symlinks or files on
    different filesystems will be treated naively.
  '';
  commonParent = a: b: let
    inherit (builtins) split filter isString concatStringsSep;
    a' = filter isString ( split "/" ( asAbspath a ) );
    b' = filter isString ( split "/" ( asAbspath b ) );
    common = lib.commonPrefix a' b';
  in if ( common == [] ) then "/" else ( concatStringsSep "/" common );


/* -------------------------------------------------------------------------- */

  __doc__realpathRel' = ''
    Get relative path between parent and subdir.
    This will not work for non-subdirs.
  '';
  realpathRel' = from: to: let
    inherit (builtins) substring stringLength length split concatStringsSep;
    p = asAbspath from;
    s = asAbspath to;
    dropP = "." + ( substring ( stringLength p ) ( stringLength s ) s );
    isSub = ( stringLength p ) < ( stringLength s );
    swapped = realpathRel' s p;
    dist = lib.count "/" swapped;
    dots = concatStringsSep "/" ( builtins.genList ( _: ".." ) dist );
  in if ( p == s ) then "." else if isSub then dropP else dots;


  __doc__realpathRel = ''
    This handles non-subdirs.
    WARNING:
    This function has no idea if your arguments are dirs or files!
    It will assume that they are directories.
    Also be mindful of how Nix may expand a Path ( type ) vs. a string.
  '';
  realpathRel = from: to: let
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

  __doc__extSuffix = ''
    Get file extension.
    This performs non-greedy matching, so `"foo.bar.baz" ==> "bar.baz"'
  '';
  extSuffix = path: let
    ms = builtins.match "[^.]*\\.(.*)" ( baseNameOf path );
  in if builtins.isNull ms then "" else builtins.head ms;


  __doc__extSuffix' = ''
    Get last file extension.
    This performs greedy matching, so `"foo.bar.baz" ==> "baz"'
  '';
  extSuffix' = path: let
    ms = builtins.match "[^.].*\\.(.*)" ( baseNameOf path );
  in if builtins.isNull ms then "" else builtins.head ms;


/* -------------------------------------------------------------------------- */

  __doc__expandGlobList = ''
    Path -> [PathGlobElem] -> [Path]
    Only directories are included, everything else is filtered out
    NOTE: Taken from `mkYarnPackage'.
  '';
  expandGlobList = base: globElems:
    if globElems == [] then [base] else let
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


  __doc__expandGlob = ''
    Path -> PathGlob -> [Path]
    Ex:
      json-utils.expandGlob ../../../../foo "bar/baz/*"
        ==>
      [ /<ABS-PATH>/foo/bar/baz/quux /<ABS-PATH>/foo/bar/baz/sally ... ]
    NOTE: Taken from `mkYarnPackage'.
  '';
  expandGlob = base: glob: expandGlobList base ( lib.splitString "/" glob );


/* -------------------------------------------------------------------------- */

  __docs__libpath = {
    inherit
      __doc__isCoercibleToPath
      __doc__coercePath
      __doc__isAbspath
      __doc__asAbspath
      __doc__categorizePath
      __doc__commonParent
      __doc__realpathRel'
      __doc__realpathRel
      __doc__extSuffix
      __doc__extSuffix'
      __doc__expandGlobList
      __doc__expandGlob
    ;
  };


/* -------------------------------------------------------------------------- */

in {

  inherit
    isCoercibleToPath
    coercePath
    isAbspath
    asAbspath
    categorizePath
    commonParent
    realpathRel'
    realpathRel
    extSuffix
    extSuffix'
    expandGlobList
    expandGlob
  ;

  inherit __docs__libpath;

}
