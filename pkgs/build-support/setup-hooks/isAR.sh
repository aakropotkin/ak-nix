# Test if a file is an AR archive.
function isAR() {
  local fn="$1"
  local fd
  local magic
  exec {fd}<"$fn"
  ### In Zsh `read -k NUM' behaves like Bash's `read -n NUM'.
  ##if test "${ZSH_VERSION+set}" = set; then
  ##  read -r -k 7 -u "$fd" magic
  ##else
  ##  read -r -n 7 -u "$fd" magic
  ##fi
  read -r -n 7 -u "$fd" magic
  exec {fd}<&-
  # First seven characters should be "!<arch>"
  if test "$magic" = $'\041\074arch\076'; then return 0; else return 1; fi
}
