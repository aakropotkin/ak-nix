{ lib, system, coreutils, bash }: let

  inherit (lib.libfs) baseName';

/* -------------------------------------------------------------------------- */

  # Use "$out" normally in `cpFlags', we'll replace it.
  # NOTE: No other shell expansions are supported.
  runcp = {
    name       ? "source"
  , src        ? null
  , srcs       ? [src]
  , cpFlags    ? ["-pr" "--reflink=auto" "--"] ++ ( map toString srcs ) ++
                 [( builtins.placeholder "out" )]
  , extraAttrs ? {}
  } @ args:
    # Make sure the user really provided SOME way for `cp' to run successfully.
    assert ! ( ( srcs == [] ) && ( src == null ) && ( ! ( args ? cpFlags ) ) );
  ( derivation {
    inherit name system;
    builder = "${coreutils}/bin/cp";
    args = let
      so = builtins.replaceStrings ["$out"] [( builtins.placeholder "out" )];
    in if ( args ? cpFlags ) then ( map so cpFlags ) else cpFlags;
  } ) // extraAttrs;


/* -------------------------------------------------------------------------- */

  copyOut = { src, name ? baseName' src, extraAttrs ? {} }:
    runcp { inherit name src extraAttrs; };


/* -------------------------------------------------------------------------- */

  copyToPath = {
    name         ? "source"
  , src, to
  , extraCpFlags ? ["-pr" "--reflink=auto"]
  , extraAttrs   ? {}
  }: assert builtins.isString to;
  ( derivation {
    inherit name system extraCpFlags src to;
    builder = "${bash}/bin/bash";
    PATH    = "${coreutils}/bin";
    passAsFile = ["buildPhase"];
    buildPhase = ''
      mkdir -p $out/${dirOf to}
      eval "cp $extraCpFlags -- $src $out/$to"
    '';
    args = ["-c" ". $buildPhasePath"];
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
  # FIXME: you can avoid `runcp' by extending replacement rules in
  # `toGNUCommandLine' to handle "$out".
  # The trick is leaving `( builtins.placeholder "out" )' as a thunk until
  # inside of `derivation { ... }'.
  cpcli = { name, argsList, extraAttrs ? {} }: let
    mkCpFlags = builtins.foldl' process [];
    process = acc: a:
      if builtins.isAttrs a then acc ++ ( lib.cli.toGNUCommandLine {} a ) else
      if builtins.isList  a then acc ++ ( mkCpFlags a ) else
      ( acc ++ [( toString a )] );
    cpFlags = mkCpFlags argsList;
  in runcp { inherit name cpFlags extraAttrs; src = []; };


/* -------------------------------------------------------------------------- */

in { inherit runcp copyOut copyToPath cpcli; }


/* -------------------------------------------------------------------------- */
