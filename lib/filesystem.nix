{ ... }: let
  inherit (builtins) head split readDir substring stringLength filter;
in rec {

/* -------------------------------------------------------------------------- */

  baseName = p: with builtins;
    let
      bp = baseNameOf ( toString p );
      isBaseName = mb: ( baseNameOf mb ) == mb;
      isNixStorePath = nsp:
        let prefix = "/nix/store/"; plen = stringLength prefix; in
        prefix == ( substring 0 plen ( toString nsp ) );
      removeNixStorePrefix = nsp:
        let m = match "/nix/store/[^-]+-(.*)" ( toString nsp ); in
        if m == null then nsp else ( head m );
    in baseNameOf ( removeNixStorePrefix ( p ) );

  baseName' = p: builtins.unsafeDiscardStringContext ( baseName p );

  baseNameOfDropExt  = p: head ( split "\\." ( baseName p ) );
  baseNameOfDropExt' = p: head ( split "\\." ( baseName' p ) );


/* -------------------------------------------------------------------------- */

  listSubdirs = dir:
    let
      inherit (builtins) attrValues mapAttrs;
      process = name: type: let bname = baseNameOf name; in
        if ( type == "directory" ) then ( ( toString dir ) + "/" + bname )
                                   else null;
      files = attrValues ( mapAttrs process ( readDir dir ) );
    in filter ( x: x != null ) files;

  listFiles = dir:
    let
      inherit (builtins) attrValues mapAttrs;
      process = name: type: let bname = baseNameOf name; in
        if ( type == "directory" ) then null
                                   else ( ( toString dir ) + "/" + bname );
      files = attrValues ( mapAttrs process ( readDir dir ) );
    in filter ( x: x != null ) files;

  listDir = dir: ( listSubdirs dir ) ++ ( listFiles dir );


/* -------------------------------------------------------------------------- */

  mapSubdirs = fn: dir: map fn ( listSubdirs dir );

  listDirsRecursive = dir:
    let dirs = listSubdirs dir; in
    builtins.foldl' ( acc: d: acc ++ ( listDirsRecursive d ) ) dirs dirs;


/* -------------------------------------------------------------------------- */

  findFileWithSuffix = dir: sfx:
    let
      fs = readDir dir;
      slen = stringLength sfx;
      suffstring = l: str: let sl = stringLength str; in
        substring ( sl - l ) sl str;
      hasSfx = s:
        ( slen <= ( stringLength s ) ) && ( suffstring slen s ) == sfx;
      matches = filter hasSfx ( builtins.attrNames fs );
    in ( toString dir ) + "/" + ( head matches );


/* -------------------------------------------------------------------------- */

}
