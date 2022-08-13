# XXX: This basically overlaps with `./attrs.nix:callFlake' except this uses
# the upstream implementation in Nix.
# It may not actually make sense to expose both but I'm doing it for now to
# experiment with them.
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
  callSubFlake = let subDir = s: if s == "" || s == null then "" else "${s}/";
  in {
    lock    ? "${root}/${subDir subdir}flake.lock"
  , root    ? ( toString ./. )
  , subdir  ? ""
  } @ args: let
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

in callSubFlake

/**
 * Included for reference, this is obviously subject to change, which is
 * why I'm importing from `nix' upstream above.
 * Presumably if/when they change `call-flake.nix' there this should break.

# nix/src/libexpr/flake/call-flake.nix
lockFileStr: rootSrc: rootSubdir:

let

  lockFile = builtins.fromJSON lockFileStr;

  allNodes =
    builtins.mapAttrs
      (key: node:
        let

          sourceInfo =
            if key == lockFile.root
            then rootSrc
            else fetchTree (node.info or {} // removeAttrs node.locked ["dir"]);

          subdir = if key == lockFile.root then rootSubdir else node.locked.dir or "";

          flake = import (sourceInfo + (if subdir != "" then "/" else "") + subdir + "/flake.nix");

          inputs = builtins.mapAttrs
            (inputName: inputSpec: allNodes.${resolveInput inputSpec})
            (node.inputs or {});

          # Resolve a input spec into a node name. An input spec is
          # either a node name, or a 'follows' path from the root
          # node.
          resolveInput = inputSpec:
              if builtins.isList inputSpec
              then getInputByPath lockFile.root inputSpec
              else inputSpec;

          # Follow an input path (e.g. ["dwarffs" "nixpkgs"]) from the
          # root node, returning the final node.
          getInputByPath = nodeName: path:
            if path == []
            then nodeName
            else
              getInputByPath
                # Since this could be a 'follows' input, call resolveInput.
                (resolveInput lockFile.nodes.${nodeName}.inputs.${builtins.head path})
                (builtins.tail path);

          outputs = flake.outputs (inputs // { self = result; });

          result = outputs // sourceInfo // { inherit inputs; inherit outputs; inherit sourceInfo; };
        in
          if node.flake or true then
            assert builtins.isFunction flake.outputs;
            result
          else
            sourceInfo
      )
      lockFile.nodes;

in allNodes.${lockFile.root}

*/
