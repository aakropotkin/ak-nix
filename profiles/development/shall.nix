{ buildEnv
, bash
, tcsh
, zsh
, ksh
, dash
}:
# You would need to create a profile script to get MANPATH
buildEnv {
  name = "shall";
  paths = [
    bash
    tcsh
    zsh
    ksh
    dash
  ];
  extraOutputsToInstall = ["man" "doc"];
}
