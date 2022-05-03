{ makeSetupHook, writeShellScriptBin }:
{
  isAR = makeSetupHook { name = "isAR"; } ./isAR.sh;
  isAR_sh = let isARContents = builtins.readFile ./isAR.sh; in
    writeShellScriptBin "isAR.sh" ( isARContents + ''
      isAR "$1"
    '' );
}
