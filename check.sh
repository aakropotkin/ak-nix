#! /usr/bin/env bash
set -eu;

: "${NIX:=nix}";
: "${NIX_FLAGS:=-L --show-trace}";
: "${SYSTEM:=$( $NIX eval --raw --impure --expr builtins.currentSystem; )}";
: "${GREP:=grep}"

export NIX_CONFIG='
warn-dirty = false
';

nix_w() {
  { $NIX "$@" 3>&2 2>&1 1>&3|$GREP -v 'warning: unknown flake output'; }  \
    3>&2 2>&1 1>&3;
}

trap '_es="$?"; exit "$_es";' HUP EXIT INT QUIT ABRT;

nix_w flake check $NIX_FLAGS --system "$SYSTEM";
nix_w flake check $NIX_FLAGS --system "$SYSTEM" --impure;

nix_w eval .#lib --apply 'lib: builtins.deepSeq lib true';
