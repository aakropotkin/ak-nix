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
  showListP = showList' ( lst: pp lst );

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

  showPrettyAttrNames = a: showPretty ( builtins.attrNames a );
  showPrettyAttrTypes = a:
    showPretty ( builtins.mapAttrs ( _: builtins.typeOf ) a );


# ---------------------------------------------------------------------------- #

  showPrettyArgs = fn: let
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

  showDoc = fn: let
    loc = "ak-nix#lib.librepl.showDoc";
  in if ! ( fn ? __functionMeta.doc )
     then throw "(${loc}): No doc string defined in `<FN>__functionMeta.doc'."
     else show "\n${fn.__functionMeta.doc}";


# ---------------------------------------------------------------------------- #

in {
  inherit
    pp

    show
    showPretty
    showPrettyCurried
    showPrettyArgs
    showPrettyAttrNames
    showPrettyAttrTypes
    showDoc

    pwd'
    pwd
  ;
  showp = showPretty;
  spp   = showPrettyCurried;
  spa   = showPrettyArgs;
  saa   = showPrettyAttrNames;
  sat   = showPrettyAttrTypes;

  # FIXME: Handle globs in the middle of paths, and names.
  ls' = lsDirGlob' "";
  ls  = lsDirGlob';

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
