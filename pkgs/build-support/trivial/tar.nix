# Create/extract gzip tarballs.
# FIXME: support Xz and bzip2

{ system, gnutar, gzip }:

let

  # Try to scrape a name from a derivation, or fall back to `default'.
  # If `x' is a list, no attempt is made to scrape a name.
  getName = default: x: let
    fromDrv = drv: drv.pname or drv.name or drv.drvAttrs.name or default;
  in if builtins.isList x then default else fromDrv x;

  stripExtension = str:
    let m = builtins.match "(.*)(\\.(tgz|tar(\\.[gxb]z)?))?" str;
    in if ( m != null ) then ( builtins.head m ) else str;


/* -------------------------------------------------------------------------- */

  # Use "$out" and "$src" normally in `tarFlags', we'll replace it.
  # NOTE: No other shell expansions are supported.
  runTar = { src, name, tarFlags ? [], extraAttrs ? {} }: ( derivation {
    inherit name system;
    PATH = "${gzip}/bin";
    builder = "${gnutar}/bin/tar";
    args = let subst = builtins.replaceStrings
                         ["$out" "$src"]
                         [( builtins.placeholder "out" ) ( toString src )];
    in map subst tarFlags;
  } ) // extraAttrs;


/* -------------------------------------------------------------------------- */

  untar = {
    tarball
  , name         ? stripExtension ( getName "source" tarball )
  , tarFlags     ? ["--no-same-owner" "--no-same-permissions"]
  , tarFlagsLate ? []
  , extraAttrs   ? {}
  }: ( derivation {
    inherit name system;
    builder = "${gnutar}/bin/tar";
    PATH    = "${gzip}/bin";
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

in { inherit runTar untar tar; }
