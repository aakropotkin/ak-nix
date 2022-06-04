let
  fcp = "https://github.com/edolstra/flake-compat/archive/master.tar.gz";
  flakeCompat = ( fetchTarball fcp );
  compat = flakeCompat { src = builtins.fetchGit ./.; };
in compat.defaultNix
