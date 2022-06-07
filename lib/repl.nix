{ lib }:
let
/* -------------------------------------------------------------------------- */

  showList = xs:
    let lines = builtins.concatStringsSep "\n" ( map toString xs );
    in builtins.trace ( "\n" + lines ) true;

  # Uses trace to print arbitrary values to the console.
  # If passed a list, each element will be printed on a line.
  show = x: showList ( if ( builtins.isList x ) then x else [x] );


/* -------------------------------------------------------------------------- */

  pwd' = builtins.getEnv "PWD";
  pwd  = toString ./.;


/* -------------------------------------------------------------------------- */

  unGlob = path:
    builtins.head ( builtins.split "\\*" ( toString path ) );

  lsDir' = dir:
    let
      files = lib.listFiles dir;
      dirs = lib.listSubdirs dir;
    in files ++ ( map ( d: d + "/" ) dirs );

  # Only handles globs at the end of paths.
  lsDirGlob' = path':
    let
      inherit (builtins) substring stringLength split head replaceStrings;
      path = toString path';
      wasAbs = lib.isAbspath path;
      ng = unGlob path;
      dir = if ( ng == "" ) then ( toString ./. ) else ( lib.asAbspath ng );
      plen = stringLength path;
      isSGlob = ( 2 <= plen ) && ( substring ( plen - 2 ) plen path ) == "/*";
      isDGlob = ( 3 <= plen ) && ( substring ( plen - 3 ) plen path ) == "/**";
      files = lib.listFiles dir;
      subs  = builtins.concatLists ( lib.mapSubdirs lib.listDir dir );
      lines = if isSGlob then ( files ++ subs ) else
              if isDGlob then ( lib.filesystem.listFilesRecursive dir ) else
              ( lsDir' dir );
      makeRel = p: lib.realpathRel' dir p;
      relLines = if wasAbs then lines else ( map makeRel lines );
    in show relLines;


/* -------------------------------------------------------------------------- */

in {
  inherit show;
  inherit pwd' pwd;
  # FIXME: Handle globs in the middle of paths, and names.
  ls' = lsDirGlob' "";
  ls  = lsDirGlob';
}
