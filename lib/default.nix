{ lib        ? ( builtins.getFlake "github:NixOS/nixpkgs?dir=lib" ).lib
, nix        ? builtins.getFlake "github:NixOS/nix"
, exportDocs ? false
}:
let

# ---------------------------------------------------------------------------- #

  lib' = lib.extend ( final: prev: let

# ---------------------------------------------------------------------------- #

    # Partitions libraries into `{ fns, doc }' fields separating any `__doc__*'
    # members from real functions.
    processDocs = sublib: let
      isDocKey  = k: ( builtins.match "__docs?__" k ) != null;
      isDocAttr = k: _: isDocKey k;
      part = { doc, fns } @ acc: name: let
        isDoc = isDocAttr name sublib.${name};
      # Detect typos
      in assert ! ( isDocKey name ); {
        doc = if isDoc then doc // { ${name} = sublib.${name}; } else doc;
        fns = if ! isDoc then fns // { ${name} = sublib.${name}; } else fns;
      };
    in builtins.foldl' part { doc = {}; fns = {}; }
                            ( builtins.attrNames sublib );


    # Detect sublibs which attempt to override existing definitions.
    detectOverrides = sublib: let
      matches = builtins.intersectAttrs prev sublib;
      conflicts = fname:
        ( builtins.unsafeGetAttrPos fname prev ) !=
        ( builtins.unsafeGetAttrPos fname sublib );
    in lib.filterAttrs ( fname: _: conflicts fname ) matches;

    # Full post-processing for sublibs
    scrubLib = sublib: let
      noDocs = ( processDocs sublib ).fns;
      noConflicts = assert ( detectOverrides noDocs ) == {}; noDocs;
    in noConflicts;


# ---------------------------------------------------------------------------- #

    callLibWith = { lib ? final, ... } @ autoArgs: x: let
      f = if lib.isFunction x then x else import x;
      args = builtins.intersectAttrs ( builtins.functionArgs f )
                                     ( { inherit lib; } // autoArgs );
    in scrubLib ( f args );

    callLib = callLibWith {};
    callLibsWith = autoArgs: lst:
      builtins.foldl' ( acc: x: acc // ( callLibWith autoArgs x ) ) {} lst;
    callLibs = callLibsWith {};


# ---------------------------------------------------------------------------- #

  in {

    # Eliminated depratation warnings/errors.
    systems = removeAttrs prev.systems ["supported"];

    libattrs  = callLib  ./attrsets.nix;
    libpath   = callLib  ./paths.nix;
    libjson   = callLib  ./json.nix;
    libstr    = callLib  ./strings.nix;
    libfs     = callLib  ./filesystem.nix;
    librepl   = callLib  ./repl.nix;
    liblist   = callLib  ./lists.nix;
    libdbg    = callLib  ./debug.nix;
    libtriv   = callLib  ./trivial.nix;
    libenc    = callLib  ./encode.nix;
    libsemver = callLib  ./semver.nix;
    libfunk   = callLibs [./funk.nix ./thunk.nix];
    libflake  = callLibs [./flake-registry.nix ./flake-utils.nix];

    # Avoid overloading the name `fetchurl' even more than it already is.
    fetchurlDrv = import ./fetchurl.nix;

    inherit (final.libattrs)
      defaultSystems
      eachSystemMap
      eachDefaultSystemMap
      currySystems
      curryDefaultSystems
      funkSystems
      funkDefaultSystems
      attrsToList
      remapKeys
      remapKeysWith
      listToAttrsBy
      foldAttrsl
    ;

    inherit (final.libjson)
      importJSON'
    ;

    inherit (final.libpath)
      isAbspath
      asAbspath
      extSuffix
      expandGlob
      realpathRel
      categorizePath
      isCoercibleToPath
      coercePath
      asDrvRelPath
    ;

    inherit (final.libstr)
      matchingLines
      readLines
      charN
      linesGrep
      readGrep
      readLinesGrep
      coerceString
      lines
      trim
      yank
      yankN
    ;

    inherit (final.libfs)
      baseName'
      baseNameOfDropExt'
      listSubdirs
      listFiles
      listDir
      findFileWithSuffix
    ;

    inherit (final.librepl)
      pp
      show
      ls
      pwd
    ;

    inherit (final.liblist)
      takeUntil
      dropUntil
      mapNoNulls
      mapDropNulls
    ;

    inherit (final.libdbg)
      report
      checkerReport
      mkCheckerDrv
      mkTestHarness
    ;

    # Other version members are already at `lib' top level from `nixpkgs'.
    inherit (final.libtriv)
      sortVersions'
      sortVersions
      latestVersion
      withHooks
    ;

    inherit (final.libenc)
      toHex fromHex
      toBase16 fromBase16
      toBase32 fromBase32
      toBase64 fromBase64
      hexToSri
      sriFile sri256File sri512File
    ;

    inherit (final.libfunk)
      canPassStrict
      canCallStrict
    ;

    __docs = processDocs.docs;

  } );

in if exportDocs then lib'.__docs else removeAttrs lib' ["__docs"]
