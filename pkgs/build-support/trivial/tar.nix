# Create/extract gzip tarballs.
# FIXME: support Xz and bzip2

{ lib, system, gnutar, gzip, coreutils, bash, findutils }:

let

  # Try to scrape a name from a derivation, or fall back to `default'.
  # If `x' is a list, no attempt is made to scrape a name.
  getName = default: x: let
    fromDrv = drv: drv.pname or drv.name or drv.drvAttrs.name or default;
  in if builtins.isList x then default else fromDrv x;

  stripExtension = str:
    let m = builtins.match "(.*)\\.(tgz|tar(\\.[gxb]z)?)" str;
    in if ( m != null ) then ( builtins.head m ) else str;


/* -------------------------------------------------------------------------- */

  # Use "$out" and "$src" normally in `tarFlags', we'll replace it.
  # "$src" replacement attempts to "do what I mean" in cases where `src' is a
  # single path-like vs. a list or path-likes, and depending on whether the
  # argument being processed matches "$src" exactly vs. contains "$src".
  #
  # When `src' is a list:
  #  - If `arg == "$src"' the list of sources are substed as separate arguments:
  #      { src = ["hey" "there"]; tarFlags = ["bar" "$src"]
  #      ==> ["bar" "hey" "there"]
  #  - If `arg contains "$src"' sources are space separated ( UNQUOTED! ):
  #      { src = ["hey" "there"]; tarFlags = ["bar" "--files='$src'"]
  #      ==> ["bar" "--files='hey there'"]
  #
  # Pay attention to the fact that the flag provided by the user provided the
  # single quotes - these are not provided for you.
  #
  # This behavior aims to align with the rules `derivation[Strict]' uses to
  # convert variables to POSIX Shell variables,
  #
  #
  # NOTE: No other shell expansions are supported.
  #
  runTar = { name, src ? [], tarFlags ? [], extraAttrs ? {} }: let
    sources = map toString ( if builtins.isList src then src else [src] );
    substSrc = args: let
      # XXX: No quoting is performed! Write them in your flags!
      joined = builtins.concatStringsSep " " sources;
      subst = acc: s:
        if ( s == "$src" ) then acc ++ sources else
        if ( lib.libstr.test ".*$src.*" s )
          then acc ++ [( builtins.replaceStrings ["$src"] [joined] s )] else
        acc ++ [s];
    in if src == [] then args else builtins.foldl' subst [] args;
  in ( derivation {
    inherit name system;
    PATH = "${gzip}/bin";
    builder = "${gnutar}/bin/tar";
    args = let
      so = builtins.replaceStrings ["$out"] [( builtins.placeholder "out" )];
      subst = arg: substSrc ( so arg );
    in map subst tarFlags;
  } ) // extraAttrs;


/* -------------------------------------------------------------------------- */

  untar = {
    tarball
  , name         ? stripExtension ( getName "source" tarball )
  , tarFlags     ? ["--no-same-owner" "--no-same-permissions"]
  , tarFlagsLate ? []
  , extraPkgs    ? []
  , extraAttrs   ? {}
  }: ( derivation {
    inherit name system;
    builder = "${gnutar}/bin/tar";
    PATH    = lib.makeBinPath ( [gzip] ++ extraPkgs );
    args = tarFlags ++ [
      "-xf" "${tarball}"
      "--one-top-level=${builtins.placeholder "out"}"
    ] ++ tarFlagsLate;
  } ) // extraAttrs;


/* -------------------------------------------------------------------------- */

  # FIXME: Use `commonParent' to set directory to invoke `tar' from?
  # Right now I think we're going to get full paths.
  # See comments in `./tests/test.nix'; but in summary: this function does not
  # currently "do what I want" in terms of handling directories.
  #
  # I strongly recomment explicitly providing individual file names, in
  # combination with "-C <PATH>", or using "--xform 's,nix/store/[^/]+/,,'"
  # to control the leading path.
  # Honestly, kind of a pain in the ass.
  # `runCommandNoCC' honestly looks real appealing right now.
  #
  # Having said that, if you're programatically generating builds, this type
  # of path cleanup is really not that painful.
  # I still intend to use this for `package.json' -> Nix work.
  #
  # NOTE: You can pass `src = []' and explicitly list files in `tarFlagsLate'.
  tar = {
    src
  , name         ? ( getName "source" src ) + ext
  , ext          ? ".tar.gz"
  , tarFlags     ? ["--no-same-owner" "--no-same-permissions"]
  , tarFlagsLate ? []
  , extraAttrs   ? {}
  }: let
    sources = if builtins.isList src then src else [src];
  in ( derivation {
    inherit name system;
    builder = "${gnutar}/bin/tar";
    PATH    = "${gzip}/bin";
    args = tarFlags     ++ ["-cf" ( builtins.placeholder "out" )] ++
           tarFlagsLate ++ sources;
  } ) // extraAttrs;


/* -------------------------------------------------------------------------- */

  # Tar `src' file(s) relative to `dir'.
  # `src' may be a single path-like, a pair of `{ dir, path }', or the results
  # of `builtins.filterSource' or `lib.cleanSource'.
  #
  # If `dir' is omitted, `lib.libfs.commonParent' will be used.
  #
  # The use of `{ dir, path }' is particularly useful for constructing a
  # directory structure explicitly.
  #
  # The option `filesOnly' prevents directory `inodes' from being written.
  # The option `stripLeadingDot' ensures that paths are written without any
  # leading "./" characters - this is often required to match the names seen
  # in software tarballs.
  tarAt = {
    src
  , dir           ? null
  , name          ? ( getName "source" src ) + ext
  , ext           ? ".tar.gz"
  , filesOnly     ? true
  , stripLeadDot  ? true
  , tarFlags      ? ["--no-same-owner" "--no-same-permissions"]
  , tarFlagsLate  ? []
  , extraAttrs    ? {}
  }: let
    sources = if builtins.isList src then src else [src];
  in ( derivation {
    inherit name system;
    builder = "${gnutar}/bin/tar";
    PATH    = "${gzip}/bin";
    args = tarFlags     ++ ["-cf" ( builtins.placeholder "out" )] ++
           tarFlagsLate ++ sources;
  } ) // extraAttrs;


/* -------------------------------------------------------------------------- */

  # We'll replace "$out" for you, but not "$src".
  # We use `lib.toGnuCommandLine' to convert our args.
  # Because that function takes attrsets, we accept a list of attrsets to allow
  # the user to use flags repeatedly.
  # This isn't ideal but whatever.
  #
  # If a member of `argsList' is not an attrset, we will recurse over lists,
  # and call `toString' on anything else.
  #
  # FIXME: you can avoid `runTar' by extending replacement rules in
  # `toGNUCommandLine' to handle "$out".
  # The trick is leaving `( builtins.placeholder "out" )' as a thunk until
  # inside of `derivation { ... }'.
  tarcli = { name, argsList, extraAttrs ? {} }: let
    mkTarFlags = builtins.foldl' process [];
    process = acc: a:
      if builtins.isAttrs a then acc ++ ( lib.cli.toGNUCommandLine {} a ) else
      if builtins.isList  a then acc ++ ( mkTarFlags a ) else
      ( acc ++ [( toString a )] );
    tarFlags = mkTarFlags argsList;
  in runTar { inherit name tarFlags extraAttrs; src = []; };


/* -------------------------------------------------------------------------- */

  untarCommand = {
    tarball
  , name          ? stripExtension ( getName "source" tarball )
  , preTar        ? ""
  , tarFlags      ? ["--no-same-owner" "--no-same-permissions"]
  , extraTarFlags ? []
  , postTar       ? ""
  , extraAttrs    ? {}
  }: ( derivation {
    inherit name system tarFlags tarball;
    builder = "${bash}/bin/bash";
    PATH =
      "${coreutils}/bin:${gnutar}/bin:${gzip}/bin:${bash}/bin:${findutils}/bin";
    passAsFile = ["buildPhase"];
    buildPhase = ''
      ${preTar}

      eval "tar $tarFlags -xf $tarball"

      ${postTar}
    '';
    args = ["-c" ". $buildPhasePath"];
  } ) // extraAttrs;


/* -------------------------------------------------------------------------- */

  # Deal with tarballs which were created by complete danguses by avoiding
  # various permissions issues.
  untarSanPerms = {
    tarball
  , name          ? stripExtension ( getName "source" tarball )
  , preTar        ? ""
  , tarFlags      ? ["--no-same-owner" "--delay-directory-restore"
                     "--no-same-permissions" "--no-overwrite-dir"]
  , tarFlagsLate  ? []
  , postTar       ? ""
  , extraAttrs    ? {}
  }: ( derivation {
    inherit name system tarFlags tarFlagsLate tarball;
    builder = "${bash}/bin/bash";
    PATH    = "${coreutils}/bin:${gnutar}/bin:${gzip}/bin:${findutils}/bin";
    passAsFile = ["buildPhase"];
    buildPhase = ''
      ${preTar}
      tar tf $tarball|xargs dirname|sort -u|xargs mkdir -p
      eval "tar $tarFlags -xf $tarball $tarFlagsLate"
      mv ./* "$out"||{ mkdir "$out"; mv ./* "$out/"; }
      ${postTar}
    '';
    args = ["-c" ". $buildPhasePath"];
  } ) // extraAttrs;


/* -------------------------------------------------------------------------- */

in { inherit runTar untar tar tarcli untarCommand untarSanPerms; }


/* -------------------------------------------------------------------------- */
