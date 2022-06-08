
# lndir is available under `nixpkgs.legacyPackages.${system}.xorg.lndir'
{ lib       ? { libfs = import ../../../lib/filesystem {}; }
, system
, coreutils
, bash
#, lndir
}:

let

  inherit (lib.libfs) baseName';

/* -------------------------------------------------------------------------- */

  # Use "$out" normally in `lnFlags', we'll replace it.
  # NOTE: No other shell expansions are supported.
  runLn = {
    name       ? "source"
  , src        ? null
  , srcs       ? [src]
  , lnFlags    ? ["-s" "--"] ++ ( map toString srcs ) ++
                 [( builtins.placeholder "out" )]
  , extraAttrs ? {}
  }@args:
    # Make sure the user really provided SOME way for `ln' to run successfully.
    assert ! ( ( srcs == [] ) && ( src == null ) && ( ! ( args ? lnFlags ) ) );
  ( derivation {
    inherit name system;
    builder = "${coreutils}/bin/ln";
    args = let
      so = builtins.replaceStrings ["$out"] [( builtins.placeholder "out" )];
    in if ( args ? lnFlags ) then ( map so lnFlags ) else lnFlags;
  } // extraAttrs );


/* -------------------------------------------------------------------------- */

  linkOut = { src, name ? baseName' src, extraAttrs ? {} }:
    runLn { inherit name src extraAttrs; };


/* -------------------------------------------------------------------------- */

  linkToPath = {
    name         ? "source"
  , src, to
  , extraLnFlags ? ["-s"]
  , extraAttrs   ? {}
  }: assert builtins.isString to;
  ( derivation {
    inherit name system extraLnFlags src to;
    builder = "${bash}/bin/bash";
    PATH    = "${coreutils}/bin";
    passAsFile = ["buildPhase"];
    buildPhase = ''
      mkdir -p $out/${dirOf to}
      ln $extraLnFlags -- $src $out/$to
    '';
    args = ["-c" ". $buildPhasePath"];
  } ) // extraAttrs;


/* -------------------------------------------------------------------------- */

  #runLndir =


/* -------------------------------------------------------------------------- */

in { inherit runLn linkOut linkToPath; }
