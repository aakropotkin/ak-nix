#! /usr/bin/env bash
set -eu;
set -o pipefail;

: "${REALPATH:=realpath}";
: "${NIX:=nix}";
: "${NIX_FLAGS:=--no-warn-dirty}";
: "${NIX_CMD_FLAGS:=-L --show-trace}";
: "${SYSTEM:=$( $NIX eval --raw --impure --expr builtins.currentSystem; )}";
: "${GREP:=grep}"
: "${JQ:=jq}";

SDIR="$( $REALPATH "${BASH_SOURCE[0]}" )";
SDIR="${SDIR%/*}";
: "${FLAKE_REF:=$SDIR}";

trap '_es="$?"; exit "$_es";' HUP EXIT INT QUIT ABRT;

nix_w() {
  {
    {
      $NIX $NIX_FLAGS "$@" 3>&2 2>&1 1>&3||exit 1;
    }|$GREP -v 'warning: unknown flake output';
  } 3>&2 2>&1 1>&3;
}

nix_w flake check "$FLAKE_REF" $NIX_CMD_FLAGS --system "$SYSTEM";
nix_w flake check "$FLAKE_REF" $NIX_CMD_FLAGS --system "$SYSTEM" --impure;

# Swallow traces, but show them on failure.
check_lib() {
  nix_w eval "$FLAKE_REF#lib" --apply 'lib: builtins.deepSeq lib true';
}
check_lib 2>/dev/null||check_lib;