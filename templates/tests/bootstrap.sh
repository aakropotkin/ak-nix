#!/usr/bin/env bash
# ============================================================================ #
#
# Fills template strings in generated files.
#
# ---------------------------------------------------------------------------- #

set -eu;

_AS_ME="${BASH_SOURCE[0]##*/}";
_SDIR="${BASH_SOURCE[0]%/*}";

: "${GIT:=git}";
: "${SED:=sed}";

: "${PROJECT:=}";
: "${SUB_NAME:=}";
: "${ROOT:=}";
export PROJECT SUB_NAME ROOT;


# ---------------------------------------------------------------------------- #

while test "$#" -gt 0; do
  case "$1" in
    -p|--proj) PROJECT="$2"; shift; ;;
    -s|--sub)  SUB_NAME="$2"; shift; ;;
    -r|--root) ROOT="$2"; shift; ;;
    *) echo "$_AS_ME: Unrecognized arg: $1" >&2; usage >&2; exit 1; ;;
  esac
  shift;
done


# ---------------------------------------------------------------------------- #

confirmVar() {
  local _var _val _p _dscp;
  _var="$1";
  shift;
  eval _val="\$_${_var:-}";
  _dscp="${*:+ ( $* )}";
  if test -z "$_val"; then
    read -p "Could not infer $_var$_dscp. What should it be? " _val;
  else
    read -N1 -p "We guessed $_var$_dscp to be '$_val'. Sound good? [Yn] " _p;
    case "$_p" in
      [Nn]*)
        read -p "Then what should it be? " _val;
      ;;
    esac
  fi
  eval $_var="$_val";
}


# ---------------------------------------------------------------------------- #

if test -z "$ROOT"; then
  if test -r "$SDIR/../flake.nix"; then
    _ROOT="$SDIR/..";
  elif ! test -d "$SDIR/.git" && test -d "$SDIR/../.git"; then
    _ROOT="$SDIR/..";
  fi
  confirmVar ROOT path to project root with flake.nix;
fi


# ---------------------------------------------------------------------------- #

if test -z "$PROJECT"; then
  _PROJECT="$( $GIT config --get remove.origin.url; )";
  _PROJECT="${_PROJECT##*/}";
  _PROJECT="${_PROJECT%.git}";
  confirmVar PROJECT your project name;
fi


# ---------------------------------------------------------------------------- #

if test -z "$SUB_NAME"; then
  confirmVar SUB_NAME name of your first test subdir;
fi


# ---------------------------------------------------------------------------- #

mv "$SDIR/sub" "$SDIR/$SUB_NAME";
$SED -i                      \
  -e "s/@NAME@/$SUB_NAME/g"  \
  -e "s/PROJECT/$PROJECT/g"  \
  "$SDIR/"*.nix              \
  "$SDIR/$SUB_NAME/"*;
$SED -i "s,^    \./sub\$,    ./$SUB_NAME," "$SDIR/default.nix";


# ---------------------------------------------------------------------------- #

read -N1 -p "Would you like to delete ${BASH_SOURCE[0]}? [Yn]" -p REPLY;
case "$REPLY" in
  [Nn]*) :; ;;
  *) rm "${BASH_SOURCE[0]}"; ;;
esac

exit 0;


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
