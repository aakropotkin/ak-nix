{ lib        ? ( builtins.getFlake "github:NixOS/nixpkgs?dir=lib" ).lib
, nix        ? builtins.getFlake "github:NixOS/nix"
, yants-src  ? builtins.fetchGit {
                 url = "https://code.tvl.fyi/depot.git:/nix/yants.git";
               }
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

    # Full post-processing for sublibs
    scrubLib = sublib: let
      noDocs = ( processDocs sublib ).fns;
    in noDocs;


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

    # Cribbed from `flake-utils', vendored to skip a redundant fetch.
    defaultSystems = [
      "x86_64-linux" "x86_64-darwin"
      "aarch64-linux" "aarch64-darwin"
      "i686-linux"
    ];


# ---------------------------------------------------------------------------- #

    # Import sub-libs
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
    libyants  = callLib  "${yants-src}/default.nix";
    libtag    = callLib  ./tags.nix;
    libtypes  = callLib  ./types.nix;

    # Avoid overloading the name `fetchurl' even more than it already is.
    fetchurlDrv = import ./fetchurl.nix;

    inherit (final.libattrs)
      eachSystemMap
      eachDefaultSystemMap
      attrsToList
      remapKeys
      remapKeysWith
      listToAttrsBy
      foldAttrsl
      joinAttrs
    ;

    inherit (final.libjson)
      importJSON'
      importJSONOr'
      importJSONOr
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
      coerceString
      lines
      trim
      yank
      yankN
      test
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
      getEnvOr
      nixEnvVars
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
      currySystems
      funkSystems
      canPassStrict
      canCallStrict
      setFunctionArgProcessor
      callWith
    ;

    inherit (final.libtag)
      discr
      discrDef
      matchLam
      matchTag
    ;

    __docs = processDocs.docs;

  } );

in if exportDocs then lib'.__docs else removeAttrs lib' ["__docs"]
