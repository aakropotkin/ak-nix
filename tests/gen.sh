#! /usr/bin/env bash
set -eu;

: "${SED:=sed}";
: "${NAME:=${1:-}}";

if test -z "$NAME"; then
  read -p "What name should we use for your tests? " NAME;
  echo '';
fi

if test -z "$NAME"; then
  echo "You didn't enter a name. Giving up." >&2;
  exit 1;
fi

if test -r "${BASH_SOURCE[0]%/*}/$NAME.nix"; then
  echo "${BASH_SOURCE[0]%/*}/$NAME.nix already exists. Giving up." >&2;
  exit 1;
fi

$SED "s,NAME,$NAME,g" "${BASH_SOURCE[0]%/*}/TEMPLATE.nix.in"  \
     > "${BASH_SOURCE[0]%/*}/$NAME.nix";

printf '%s' "Be sure to add this $NAME.nix to your imports in "  \
            "${BASH_SOURCE[0]%/*}/default.nix" >&2;
