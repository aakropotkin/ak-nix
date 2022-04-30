{ stdenv
, autoreconfHook
}:
stdenv.mkDerivation {
  pname   = "@PROJECT@";
  version = "@VERSION@";
  src     = ./.;
  nativeBuildInputs = [
    autoreconfHook
  ];
}
