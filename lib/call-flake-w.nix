{ nix ? builtins.getFlake "github:NixOS/nix/master" }:
let

  /**
   *  This is the "raw" form of `builtins.getFlake'.
   *  This can be useful if you are creating a fake lockfile.
   *  Notice that the "inner" `_raw' function accepts the lockfile as a JSON
   *  string rather than a path.
   *
   *  callFlake { lock = ./flake.lock; root = ./.; }
   */
  callFlake = let subDir = s: if s == "" || s == null then "" else "${s}/";
  in args @ {
    lock    ? "${root}/${subDir subdir}flake.lock"
  , root    ? ( toString ./. )
  , subdir  ? ""
  }: let
    inherit (builtins) substring readFile pathExists;
    lockFileStr =
      if isPath lock then readFile lock else
      if isString lock && pathExists lock then readFile lock else
      if isAttrs lock && lock ? outPath then readFile ( toString lock ) else
      lock;

    rootSrc = if isAttrs root && root ? narHash then root else
    builtins.fetchTree { type = "path"; path = toString root; };

    _raw = import "${nix}/src/libexpr/flake/call-flake.nix";
  in _raw lockFileStr rootSrc subdir;

in callFlake
