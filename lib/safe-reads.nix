# ============================================================================ #
#
# Eval time hints indicating if reading a path might get you killed.
# Look before you leap.
#
# I use it to split "build plan eval" ( instantiation ) operations that need
# impure, from execution of the build plan ( realization ) in a single run.
# This allows you to dynamically declare reproducible derivations using
# inference without writing anything to disk or spinning up a second
# "pure pass" after an impure run.
# This isn't anything new, flakes in particular have to deal with this a lot.
# These routines are just guard rails to help you develop without shooting
# yourself in the foot and accidentally poisoning a generation of builds.
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  # Mimics the `allowedPaths' in `libexpr'.
  # We lack any type of introspection to know what the list is with a query,
  # but the user can populate this list themselves.
  # In practice you aren't going to emulate the real construct,
  # but it's useful for path crawling in pure mode and artificial limiting in
  # impure mode.
  isAllowedPath = { allowedPaths }: path:
    ( builtins.any ( allow: lib.hasPrefix allow path ) allowedPaths );


# ---------------------------------------------------------------------------- #

  # `getContext' returns `{ <PATH> = { allOutputs = <BOOL>; }; }' for `*.drv',
  # `{ <PATH> = { outputs = ["out" ...]; }; }' for derivation outputs,
  # and `{ <PATH> = { path = <STRING>; }; }` for builtin outputs.
  # We care about the second form of path.
  readNeedsIFD = pathlike: let
    str = if builtins.isString pathlike then pathlike else
          pathlike.outPath or ( toString pathlike );
    ctx      = builtins.attrValues ( builtins.getContext str );
    hasOP    = builtins.any ( x: x ? outputs ) ctx;
    forAttrs = ( pathlike ? drvPath ) ||
               ( ( ( pathlike ? outPath ) || ( pathlike ? __toString ) ) &&
                 hasOP );
  in if builtins.isAttrs pathlike then forAttrs else hasOP;


# ---------------------------------------------------------------------------- #

  readNeedsImpureStrict = pathlike: let
    str = if builtins.isString pathlike then pathlike else
          pathlike.outPath or ( toString pathlike );
    ctx      = builtins.getContext str;
    forAttrs = ( ( pathlike.drvPath or pathlike.outPath or null ) == null ) ||
               ( ctx == {} );
  in if builtins.isPath pathlike then ! ( lib.isStorePath pathlike ) else
     if builtins.isAttrs pathlike then forAttrs else
     ( ctx == {} );


# ---------------------------------------------------------------------------- #

  readNeedsImpureExcept = { allowedPaths }: pathlike:
    ( readNeedsImpureStrict pathlike ) &&
    ( ! ( isAllowedPath { inherit allowedPaths; } ( toString pathlike ) ) );

  readNeedsImpure = { allowedPaths ? [] }: pathlike:
    readNeedsImpureExcept { inherit allowedPaths; } pathlike;


# ---------------------------------------------------------------------------- #

  readAllowed' = { pure, ifd, allowedPaths }: pathlike: let
    isImpure       = readNeedsImpureExcept { inherit allowedPaths; } pathlike;
    inAllowedPaths = isAllowedPath { inherit allowedPaths; } pathlike;
    needsIFD = readNeedsIFD pathlike;
    pureOk   = ( ! pure ) || inAllowedPaths || ( ! isImpure );
    ifdOk    = ifd || ( ! needsIFD );
    ifdMsg   = "Cannot read path '${toString pathlike}' without IFD.";
    pureMsg  = "Cannot read unlocked path '${toString pathlike}' in pure mode.";
    err'     = if ifdOk && pureOk then {} else {
      err = if ifdOk then pureMsg else ifdMsg;
    };
  in {
    ok = pureOk && ifdOk;
    inherit isImpure inAllowedPaths needsIFD;
    rules = { inherit pure ifd allowedPaths; };
  } // err';

  readAllowed = { pure, ifd, allowedPaths ? [] }: pathlike:
    ( readAllowed' { inherit pure ifd allowedPaths; } pathlike ).ok;


# ---------------------------------------------------------------------------- #

  runReadOp = { pure, ifd, allowedPaths } @ renv: op: pathlike: let
    check = readAllowed' renv pathlike;
    msg   = if ! ( op ? __functionMeta.name ) then check.err else
            "${op.__functionMeta.name}): ${check.err}";
  in if check.ok then op pathlike else throw msg;


  defSafeReaders = { pure, ifd, allowedPaths } @ renv: let
    ops = {
      inherit (builtins) readFile readDir pathExists path;
      inherit (lib) importJSON;
    };
  in builtins.mapAttrs ( _: runReadOp renv ) ops;


# ---------------------------------------------------------------------------- #

  runtimeEnvReaders = defSafeReaders {
    pure         = lib.inPureEvalMode;
    allowedPaths = [];
    ifd          = true;  # For cross eval: `builtins.currentSystem == system'
  };


# ---------------------------------------------------------------------------- #

in {
  inherit
    isAllowedPath
    readNeedsIFD
    readNeedsImpureStrict readNeedsImpureExcept readNeedsImpure
    readAllowed' readAllowed
    runReadOp
    defSafeReaders
    runtimeEnvReaders
  ;
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
