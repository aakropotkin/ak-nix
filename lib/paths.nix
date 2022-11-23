# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  yt = lib.ytypes // lib.ytypes.Core // lib.ytypes.Prim;

# ---------------------------------------------------------------------------- #

  strp = yt.Typeclasses.stringy.check;

# ---------------------------------------------------------------------------- #

  __doc__isCoercibleToPath = ''
    Can `x' be coerced to a Path?
  '';
  isCoercibleToPath = yt.Typeclasses.pathlike.check;


  __doc__coercePath = ''
    Force a path-like `x' to be a Path.
    NOTE: unlike the `pathlike' Typeclass we don't accept 'fetchTree' args.
  '';
  coercePath = x:
    if builtins.isPath x then x else
    x.outPath or (
      if ! ( strp x ) then
        throw "Cannot coerce a path from type: ${builtins.typeOf x}" else
      if isAbspath x then /. + "${x}" else ./. + "/${toString x}"
    );


# ---------------------------------------------------------------------------- #

  __doc__isAbspath = ''
    Is path-like `x' an absolute path?
    This is always true for Path types, but we're really interested in checking
    for whether or not a relative path-like (string) needs to be resolved.
  '';
  isAbspath = x:
    if builtins.isPath x then true else
    if ! ( strp x ) then
      throw "Cannot get absolute path of type: ${builtins.typeOf x}"
    else ( x != "" ) && ( ( builtins.substring 0 1 x ) == "/" );


  __doc__asAbspathstrEvil = ''
    Resolve a relative path to an absolute pathstring.
    This is a dirty implementation that uses the evaluator's CWD to resolve
    relative paths.
  '';
  asAbspathstrEvil = path: let
    str = toString path;
  in if isAbspath path then str else ./. + ( "/" + str );


  __doc__asAbspath = ''
    Resolve a relative path to an absolute pathstring.
    Uses `basedir' to resolve relative paths.
  '';
  asAbspath' = basedir: path:
    if isAbspath path then toString path else
    if builtins.isPath basedir then basedir + ( "/" + path ) else
    /. + ( basedir + "/" + path );

  asAbspath = x:
    if ( builtins.isString x ) || ( builtins.isPath x ) then asAbspath' x else
    if ( x ? basedir ) && ( x ? path ) then asAbspath' x.basedir x.path else
    if ( x ? basedir ) && ( x ? relpath ) then asAbspath' x.basedir x.relpath
    else asAbspath' ( x.basedir or ( toString x ) );


# ---------------------------------------------------------------------------- #

  __doc__categorizePath = ''
    Return inode type for path-like `x', being one of "directory", "regular",
    "symlink", "symlinkdir", or "unknown" ( for sockets and other oddities ).
    Path-like `x' must exist, and is processed by `coercePath', allowing strings
    and relative paths to be used.
    If the path is a symlink, `pathExists' will be invoked to detect
    `symlink' vs. `symlinkdir'.
  '';
  categorizePath = x: let
    p = coercePath x;
    c = ( builtins.readDir ( dirOf p ) ).${baseNameOf p};
    # XXX: This will NOT work without the quotes because the lexer will drop
    #      the trailing dot from a "raw" path!
    isSymlinkDir = builtins.pathExists "${toString p}/.";
  in assert isCoercibleToPath x; assert builtins.pathExists p;
     if c != "symlink" || ! isSymlinkDir then c else "symlinkdir";


# ---------------------------------------------------------------------------- #

  __doc__commonParent = ''
    Return the nearest common parent directory for path-likes `a' and `b'.
    This will eventually fall back to "/" if needed.
    Common parent is detected by path splitting alone - symlinks or files on
    different filesystems will be treated naively.
  '';
  commonParent = a: b: let
    splitSlash = s: builtins.filter builtins.isString ( builtins.split "/" s );
    a' = splitSlash ( asAbspath a );
    b' = splitSlash ( asAbspath b );
    common = lib.liblist.commonPrefix a' b';
  in if ( common == [] ) then "/" else ( builtins.concatStringsSep "/" common );


# ---------------------------------------------------------------------------- #

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
    dist = lib.libstr.countMatches "/" swapped;
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
    parent       = commonParent from to;
    fromToParent = realpathRel' from parent;
    parentToTo   = realpathRel' parent to;
    joined       = "${fromToParent}/${parentToTo}";
    san = builtins.replaceStrings ["/./"] ["/"] joined;
    sanF = s: let m = builtins.match "(\\./)(.*)" s; in
              if ( m == null ) then s else ( builtins.elemAt m 1 );
    sanE = s: let m = builtins.match "(.*)(/\\.)" s; in
              if ( m == null ) then s else ( builtins.head m );
  in sanE ( sanF san );


# ---------------------------------------------------------------------------- #

  __doc__dropLeadingDotSlash = ''
    Try to drop leading "./" part of path-like String `p'.
  '';
  dropLeadingDotSlash = p: let
    y = lib.libstr.yank "\\./(.*)" p;
  in if ( y == null ) then p else y;


# ---------------------------------------------------------------------------- #

  __doc__stripComponents = ''
    Strip `n' count leading directory components from path-like `p'.
    Returns a path-like string without any "./" components.
    When stripping, leading "./" components DO COUNT against `n'.
    Redundant slashes, eg "foo//bar//baz", are counted as a single component,
    but no "fixup" on repeated slashes is performed on the resulting string.
  '';
  stripComponents = n: p: let
    inherit (builtins) genList concatStringsSep;
    stripper = ( concatStringsSep "" ( genList ( _: "[^/]*/+" ) n ) ) + "(.*)";
    s = lib.libstr.yank stripper ( toString p );
  in if ( s == null ) then ( baseNameOf p ) else s;


# ---------------------------------------------------------------------------- #

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


# ---------------------------------------------------------------------------- #

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
      expandGlob ../../../../foo "bar/baz/*"
        ==>
      [ /<ABS-PATH>/foo/bar/baz/quux /<ABS-PATH>/foo/bar/baz/sally ... ]
    NOTE: Taken from `mkYarnPackage'.
  '';
  expandGlob = base: glob: expandGlobList base ( lib.splitString "/" glob );


# ---------------------------------------------------------------------------- #

  __doc__asDrvRelPath = ''
    Strip store path prefix from path.
    Non-store paths are returned "as is".
    Filepaths ( as opposed to sub-paths ) like `.drv' files yield "".

      /nix/store/5l6qb6jwzqdy7zljrmx0rylavn8awyxi-hello-2.12/bin/hello
      ==>
      bin/hello

      /nix/store/5l6qb6jwzqdy7zljrmx0rylavn8awyxi-hello-2.12.drv ==> ""

      ./foo/bar ==> ./foo/bar
      foo/bar   ==> foo/bar
  '';
  asDrvRelPath = p: let
    a = asAbspath p;
    m = builtins.match ".*/[${lib.libstr.base32Chars'}]\{32\}-[^/]*/(.*)" a;
  in if m != null then ( builtins.head m ) else
     if ! ( lib.isStorePath p ) then p else "";


# ---------------------------------------------------------------------------- #

in {

  inherit
    isCoercibleToPath
    coercePath
    isAbspath
    asAbspath' asAbspath
    categorizePath
    commonParent
    realpathRel'
    realpathRel
    dropLeadingDotSlash
    stripComponents
    extSuffix
    extSuffix'
    expandGlobList
    expandGlob
    asDrvRelPath
  ;

  # Dump Docs:
  # nix eval --json -f ./default.nix --apply 'f: f { exportDocs = true; }'  \
  #   |jq -r '.[]|to_entries|map( .key + ":\n" + .value + "\n"  )[]';
  __docs__libpath = {
      isCoercibleToPath   = __doc__isCoercibleToPath;
      coercePath          = __doc__coercePath;
      isAbspath           = __doc__isAbspath;
      asAbspath           = __doc__asAbspath;
      categorizePath      = __doc__categorizePath;
      commonParent        = __doc__commonParent;
      realpathRel'        = __doc__realpathRel';
      realpathRel         = __doc__realpathRel;
      dropLeadingDotSlash = __doc__dropLeadingDotSlash;
      stripComponents     = __doc__stripComponents;
      extSuffix           = __doc__extSuffix;
      extSuffix'          = __doc__extSuffix';
      expandGlobList      = __doc__expandGlobList;
      expandGlob          = __doc__expandGlob;
  };

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
