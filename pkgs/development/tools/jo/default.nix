{ stdenv
, autoreconfHook
, pkg-config
, pandoc
, jo-src ? builtins.fetchGit {
             url = "https://github.com/jpmens/jo.git";
             ref = "refs/tags/1.6";
             rev = "6962bca178a6778328d1126ff762120305bb4327";
           }
}:
stdenv.mkDerivation {
  pname   = "jo";
  version = "1.6";
  src     = jo-src;
  nativeBuildInputs = [
    pkg-config
    pandoc
    autoreconfHook
  ];
}
