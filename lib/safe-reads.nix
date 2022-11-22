# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  yt = lib.ytypes // lib.ytypes.Core // lib.ytypes.Prim;

# ---------------------------------------------------------------------------- #

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
    forAttrs = ( ( pathlike.drvPath or pathlike.outPath or null ) != null ) ||
               ( ctx != {} );
  in if builtins.isPath pathlike then ! ( lib.isStorePath pathlike ) else
     if builtins.isAttrs pathlike then forAttrs else
     ( ctx != {} );


# ---------------------------------------------------------------------------- #


  readNeedsImpureExcept = { allowedPaths }: pathlike: let
    str = toString pathlike;
  in ( readNeedsImpureStrict pathlike ) &&
     ( ! ( isAllowedPath { inherit allowedPaths; } ) );

  readNeedsImpure = { allowedPaths ? [] }: pathlike:
    readNeedsImpureExcept { inherit allowedPaths; } pathlike;


# ---------------------------------------------------------------------------- #


  readAllowed' = { pure, ifd, allowedPaths }: pathlike: let
    isImpure       = readNeedsImpureExcept { inherit allowedPaths; } pathlike;
    inAllowedPaths = isAllowedPath { inherit allowedPaths; };
    needsIFD       = readNeedsIFD pathlike;
    pureOk         = ! ( pure && isImpure );
    ifdOk          = ifd || ( ! ifd );
    ifdMsg  = "Cannot read path '${toString pathlike}' without IFD.";
    pureMsg = "Cannot read unlocked path '${toString pathlike}' in pure mode.";
    err'    = if ifdOk && pureOk then {} else {
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
    ifd          = true;
  };


# ---------------------------------------------------------------------------- #

in {
  inherit
    isAllowedPath
    readNeedsIFD
    readNeedsImpureStrict readNeedsImpureExcept
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
