# See instructions in the `instruct' text below.
{ nixpkgs   ? builtins.getFlake "nixpkgs"
, system    ? builtins.currentSystem
, pkgs      ? nixpkgs.legacyPackages.${system}
, writeText ? pkgs.writeText
, myPlugin    ? pkgs.myPlugin  # FIXME
}: let
  instruct = "\n\n" + ''
    Build this config file using:
      nix build -f ./default.nix --out-link ~/.config/nix/plugin.conf
    
    Include this in `~/.config/nix/nix.conf' or a similar config file as:
      !include ./plugin.conf
    
    If you would like to add this to a different config, such as
    `/etc/nix/nix.conf', just be sure change `--out-link' appropriately.
    
    If you would like to refer directly to the Nix Store, you can register
    this derivation as a GC root, and modify your include line to be:
      include /nix/store/XXXXXXXXX...-plugin.conf
  ''; 
  # FIXME
  nixConf = import ./plugin.nix { inherit system writeText myPlugin; };
in builtins.trace instruct nixConf
