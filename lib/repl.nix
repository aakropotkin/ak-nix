# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  pp = lib.generators.toPretty { allowPrettyValues = true; };

# ---------------------------------------------------------------------------- #

  showList' = printer: xs: let
    lines = builtins.concatStringsSep "\n" ( map printer xs );
  in builtins.trace ( "\n" + lines ) "";
  showList  = showList' lib.libstr.coerceString;
  showListP = showList' ( lst: "\n${pp lst}\n" );

  # Uses trace to print arbitrary values to the console.
  # If passed a list, each element will be printed on a line.
  show  = x: showList  ( if ( builtins.isList x ) then x else [x] );

  showPretty = x: showListP ( if ( builtins.isList x ) then x else [x] );
  showPrettyCurried = {
    __curr = x: x;
    __functor = self: x: let
      y = self.__curr x;
    in if builtins.isFunction y then self // { __curr = y; }
                                else showPretty y;
  };


# ---------------------------------------------------------------------------- #

  prettyArgs = fn: let
    args     = lib.functionArgs fn;
    allBools = builtins.all builtins.isBool ( builtins.attrValues args );
    showOpt  = builtins.mapAttrs ( _: v: if v then "Optional" else "Mandatory" )
                                 args;
  in showPretty ( if allBools then showOpt else args );


# ---------------------------------------------------------------------------- #

  pwd' = builtins.getEnv "PWD";
  pwd  = toString ./.;


# ---------------------------------------------------------------------------- #

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
      inherit (builtins) concatLists;
      path = toString path';
      wasAbs = lib.libpath.isAbspath path;
      ng = unGlob path;
      dir = if ( ng == "" ) then ( toString ./. )
                            else ( lib.libpath.asAbspath ng );
      plen = stringLength path;
      isSGlob = ( 2 <= plen ) && ( substring ( plen - 2 ) plen path ) == "/*";
      isDGlob = ( 3 <= plen ) && ( substring ( plen - 3 ) plen path ) == "/**";
      files = lib.listFiles dir;
      subs  = concatLists ( lib.libfs.mapSubdirs lib.libfs.listDir dir );
      lines = if isSGlob then ( files ++ subs ) else
              if isDGlob then ( lib.filesystem.listFilesRecursive dir ) else
              ( lsDir' dir );
      makeRel = lib.libpath.realpathRel' dir;  # dir -> path -> rel-path
      relLines = if wasAbs then lines else ( map makeRel lines );
    in show relLines;


# ---------------------------------------------------------------------------- #

in {
  inherit
    pp

    show
    showPretty
    showPrettyCurried
    prettyArgs

    pwd'
    pwd
  ;
  showp = showPretty;
  spp   = showPrettyCurried;
  spa   = prettyArgs;

  # FIXME: Handle globs in the middle of paths, and names.
  ls' = lsDirGlob' "";
  ls  = lsDirGlob';
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
