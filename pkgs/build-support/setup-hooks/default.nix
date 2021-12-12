{ makeSetupHook, ... }:
{
  isAR = makeSetupHook { name = "isAR"; } ./isAR.sh;
}
