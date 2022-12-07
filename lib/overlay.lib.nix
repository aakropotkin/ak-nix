# ============================================================================ #
#
# Overlays Nixpkgs' `lib' adding new sublibs.
# Additionally this initializes a "core" set of YANTS types: `ytypes'.
#
# ---------------------------------------------------------------------------- #

final: prev: let

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

  # NOTE: previously an argument `exportDocs' would add an attribute
  # `__docs' which stashed the content produced by `processDocs.docs'.
  # When migrating to an overlay this was removed since I lacked a clear way
  # to indicate this argument without having it appear in the overlay itself.


# ---------------------------------------------------------------------------- #

  callLibWith = { lib ? final, ... } @ auto: x: let
    f = if lib.isFunction x then x else import x;
    args = builtins.intersectAttrs ( builtins.functionArgs f )
                                   ( { inherit lib; } // auto );
  in scrubLib ( f args );

  callLib = callLibWith {};
  callLibsWith = auto:
    builtins.foldl' ( acc: x: acc // ( callLibWith auto x ) ) {};
  callLibs = callLibsWith {};


# ---------------------------------------------------------------------------- #

  # Backport missing `lib.inPureEvalMode'
  # NOTE: only injected if missing so `pos' isn't disturbed.
  backport.inPureEvalMode = ! ( builtins ? currentSystem );

  backportFns = let
    proc = acc: fname:
    if prev ? ${fname} then acc else acc // { ${fname} = backport.${fname}; };
  in builtins.foldl' proc {} ( builtins.attrNames backport );


# ---------------------------------------------------------------------------- #

in backportFns // {

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
  libtag    = callLib  ./tags.nix;
  libtypes  = callLib  ./types.nix;
  libfilt   = callLib  ./filt.nix;
  libread   = callLib ./safe-reads.nix;

  inherit (final.libread)
    readNeedsIFD
    readNeedsImpure
    readAllowed
    runReadOp
  ;

  inherit (final.libfilt)
    genericFilt
    nixFilt
  ;

  inherit (final.libattrs)
    eachSystemMap
    eachDefaultSystemMap
    attrsToList
    remapKeys
    remapKeysWith
    listToAttrsBy
    foldAttrsl
    joinAttrs
    diffAttrs
    applyAttrs
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
    isTarballUrl
    nameFromTarballUrl
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
    pp ls pwd
    show
    showPretty
    showPrettyArgs
    showPrettyAttrNames
    showPrettyAttrTypes
    showDoc
    spp
    spa
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
    callWith
    apply
    callWithOvStrict
    callWithOvStash
    callWithOv
    setFunctionArgProcessor setFunkArgProcessor
    setFunkMetaField
    setFunkProp
    setFunkDoc
    processArgs
    defunk
    funkName
  ;

  inherit (final.libtag)
    discr
    discrDef
    matchLam
    matchTag
    tagName
    tagValue
  ;


# ---------------------------------------------------------------------------- #

  ytypes = let
    libyants = callLib ./yants.nix;
    core = prev.makeExtensible ( ytFinal: {
      inherit (libyants) __internal;
      inherit (final.libtypes.ytypes) Typeclasses Attrsets;
      inherit (final.libfunk.ytypes) Funk;
      Strings = final.libstr.ytypes.Strings // ytFinal.Hash.Strings;
      Prim    = libyants.Prim // final.libtypes.ytypes.Prim;
      Hash    = final.libenc.ytypes;
      Core    = libyants.Core // final.libtypes.ytypes.Core;
    } );
  in core.extend ( import ../types/overlay.yt.nix );


# ---------------------------------------------------------------------------- #

}  # End Overlay


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
