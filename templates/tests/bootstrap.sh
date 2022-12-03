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
: "${REALPATH:=realpath}";

: "${PROJECT:=}";
: "${SUB_NAME:=}";
: "${ROOT:=}";
export PROJECT SUB_NAME ROOT;

usage() {
  {
    echo "$_AS_ME [-p PROJECT] [-s SUB_NAME] [-r ROOT]";
    echo "-p|--proj  project name";
    echo "-s|--sub   test subdir name";
    echo "-r|--root  path to project root ( with flake.nix )";
  }
}


# ---------------------------------------------------------------------------- #

while test "$#" -gt 0; do
  case "$1" in
    -p|--proj) PROJECT="$2"; shift; ;;
    -s|--sub)  SUB_NAME="$2"; shift; ;;
    -r|--root) ROOT="$2"; shift; ;;
    -h|--help) usage >&2; exit 0; ;;
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
    echo '';
  else
    read -n 1 -p "We guessed $_var$_dscp to be '$_val'. Sound good? [Yn] " _p;
    echo '';
    case "$_p" in
      [Nn]*)
        read -p "Then what should it be? " _val;
        echo '';
      ;;
    *) :; ;;
    esac
  fi
  eval $_var="$_val";
}


# ---------------------------------------------------------------------------- #

if test -z "$ROOT"; then
  if test -r "$_SDIR/../flake.nix"; then
    _ROOT="$_SDIR/..";
  elif ! test -d "$_SDIR/.git" && test -d "$_SDIR/../.git"; then
    _ROOT="$_SDIR/..";
  fi
  confirmVar ROOT path to project root with flake.nix;
fi


# ---------------------------------------------------------------------------- #

if test -z "$PROJECT"; then
  _PROJECT="$( $GIT config --get remote.origin.url||:; )";
  _PROJECT="${_PROJECT##*/}";
  _PROJECT="${_PROJECT%.git}";
  confirmVar PROJECT your project name;
fi


# ---------------------------------------------------------------------------- #

if test -z "$SUB_NAME"; then
  _SUB_NAME='';
  confirmVar SUB_NAME name of your first test subdir;
fi


# ---------------------------------------------------------------------------- #

case "$SUB_NAME" in
  sub) :; ;;
  *)
    echo "Moving $_SDIR/sub to $_SDIR/$SUB_NAME" >&2;
    mv "$_SDIR/sub" "$_SDIR/$SUB_NAME";
  ;;
esac
echo "Substituting variables in to template files:" >&2;
echo "  $_SDIR/"*.nix "$_SDIR/$SUB_NAME/"*;
$SED -i                      \
  -e "s/@NAME@/$SUB_NAME/g"  \
  -e "s/PROJECT/$PROJECT/g"  \
  "$_SDIR/"*.nix             \
  "$_SDIR/$SUB_NAME/"*;
$SED -i "s,^    \./sub\$,    ./$SUB_NAME," "$_SDIR/default.nix";


# ---------------------------------------------------------------------------- #

if test "$( $REALPATH $ROOT; )" != "$( $REALPATH $_SDIR; )"; then
  read -n 1 -p "Would you like to move check.sh to the project root? [Yn]";
  echo '';
  case "$REPLY" in
    [Nn]*)
      {
        echo "NOTE: if you plan to use 'check.sh' outside of the project root";
        echo "be sure to edit its 'SDIR' and 'FLAKE_REF' setup accordingly.";
      } >&2;
      sleep 1s;
    ;;
    *) mv "$_SDIR/check.sh" "$ROOT/check.sh"; ;;
  esac
fi


# ---------------------------------------------------------------------------- #

read -n 1 -p "Would you like to delete ${BASH_SOURCE[0]}? [Yn]";
echo '';
case "$REPLY" in
  [Nn]*) :; ;;
  *) rm "${BASH_SOURCE[0]}"; ;;
esac


# ---------------------------------------------------------------------------- #

read -n 1 -p "Would you like to add these files to 'git'? [Yn]";
echo '';
case "$REPLY" in
  [Nn]*) :; ;;
  *)
    if test -r "$ROOT/check.sh"; then
      $GIT add "$ROOT/check.sh";
    fi
    $GIT add "$_SDIR";
  ;;
esac


# ---------------------------------------------------------------------------- #

exit 0;


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
