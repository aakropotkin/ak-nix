{ lib        ? ( builtins.getFlake "nixpkgs" ).lib
, utils      ? builtins.getFlake "github:numtide/flake-utils"
, exportDocs ? false
}:
let
  lib' = lib.extend ( final: prev:
    let callLibs = file: import file { lib = final; };
    in {

      # Eliminated depratation warnings/errors.
      systems = removeAttrs prev.systems ["supported"];

      libattrs = import   ./attrsets.nix { lib = final; inherit utils; };
      libpath  = callLibs ./paths.nix;
      libjson  = callLibs ./json.nix;
      libstr   = callLibs ./strings.nix;
      libfs    = callLibs ./filesystem.nix;
      librepl  = callLibs ./repl.nix;
      liblist  = callLibs ./lists.nix;
      libdbg   = callLibs ./debug.nix;
      libtriv  = callLibs ./trivial.nix;
      libenc   = callLibs ./encode.nix;

      # Avoid overloading the name `fetchurl' even more than it already is.
      fetchurlDrv = import ./fetchurl.nix;

      inherit (final.libattrs)
        currySystems
        curryDefaultSystems
        funkSystems
        funkDefaultSystems
        attrsToList
      ;

      inherit (final.libjson)
        importJSON';

      inherit (final.libpath) __docs__libpath
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
        show
        ls
        pwd
      ;

      inherit (final.liblist)
        takeUntil
        dropUntil
      ;

      inherit (final.libdbg)
        report
        checker
        checkerDrv
        mkTestHarness
      ;

      # Other version members are already at `lib' top level from `nixpkgs'.
      inherit (final.libtriv)
        sortVersions'
        sortVersions
        latestVersion
      ;

      inherit (final.libenc)
        toHex fromHex
        toBase16 fromBase16
        toBase32 fromBase32
        toBase64 fromBase64
        hexToSri
        sriFile sri256File sri512File
      ;

    } );

  # FIXME: you're leaving behind sub-attributes like `libpath.__docs__libpath'
  docsParted = let
    ptd = builtins.partition
      ( x: lib.hasPrefix "__docs__" x.name )
      ( lib'.attrsToList lib' );
    # I intentionally left "__doc_" short on the suffix in case I mistype.
    throwDoc = k: v: if ( ! lib.hasPrefix "__doc_" k ) then v else
      throw "Found docstring in lib exports: ${k}";
    assertNoDocs = builtins.mapAttrs throwDoc;
  in {
    docs = builtins.listToAttrs ptd.right;
    lib  = assertNoDocs ( builtins.listToAttrs ptd.wrong );
  };

in if exportDocs then docsParted.docs else docsParted.lib
