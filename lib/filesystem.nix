_: let

  inherit (builtins) head split readDir substring stringLength filter;

# ---------------------------------------------------------------------------- #

  baseName = p: let
    isBaseName = mb: ( baseNameOf mb ) == mb;
    isNixStorePath = nsp: let
      prefix = "/nix/store/";
      plen   = stringLength prefix;
    in prefix == ( substring 0 plen ( toString nsp ) );
    removeNixStorePrefix = nsp: let
      m = builtins.match "/nix/store/[^-]+-(.*)" ( toString nsp );
    in if m == null then nsp else ( head m );
  in baseNameOf ( removeNixStorePrefix p );

  baseName' = p: builtins.unsafeDiscardStringContext ( baseName p );

  baseNameOfDropExt  = p: head ( split "\\." ( baseName p ) );
  baseNameOfDropExt' = p: head ( split "\\." ( baseName' p ) );


# ---------------------------------------------------------------------------- #

  listSubdirs = dir: let
    proc = name: type:
      if type == "directory" then toString ( dir + "/${name}" ) else null;
    inodes = builtins.readDir dir;
    ents   = builtins.attrValues ( builtins.mapAttrs proc inodes );
  in builtins.filter ( x: x != null ) ents;

  listFiles = dir: let
    proc = name: type:
      if type == "directory" then null else toString ( dir + "/${name}" );
    inodes = builtins.readDir dir;
    ents   = builtins.attrValues ( builtins.mapAttrs proc inodes );
  in builtins.filter ( x: x != null ) ents;

  listDir = dir: let
    inodes = builtins.readDir dir;
  in map ( name: toString ( dir + "/${name}" ) ) ( builtins.attrNames inodes );


# ---------------------------------------------------------------------------- #

  mapSubdirs = fn: dir: map fn ( listSubdirs dir );

  listDirsRecursive = dir: let
    dirs = listSubdirs dir;
  in builtins.foldl' ( acc: d: acc ++ ( listDirsRecursive d ) ) dirs dirs;


# ---------------------------------------------------------------------------- #

  findFileWithSuffix = dir: sfx: let
    slen = stringLength sfx;
    suffstring = l: str: let
      sl = stringLength str;
    in substring ( sl - l ) sl str;
    hasSfx = s:
      ( slen <= ( stringLength s ) ) && ( suffstring slen s ) == sfx;
    matches = filter hasSfx ( builtins.attrNames ( readDir dir ) );
  in "${toString dir}/${head matches}";


# ---------------------------------------------------------------------------- #
in {
  inherit
    baseName
    baseName'
    baseNameOfDropExt
    baseNameOfDropExt'
    listSubdirs
    listFiles
    listDir
    mapSubdirs
    listDirsRecursive
    findFileWithSuffix
  ;
}
