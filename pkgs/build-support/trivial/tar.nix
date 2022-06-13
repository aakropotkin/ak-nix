# Create/extract gzip tarballs.
# FIXME: support Xz and bzip2

{ system, gnutar, gzip }:

let

  getName = default: drv: drv.pname or drv.name or drv.drvAttrs.name or default;

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

in { inherit runTar untar tar; }
