# Test if a file is an AR archive.
function isAR() {
  local fn="$1"
  local fd
  local magic
  exec {fd}< "$fn"
  read -r -n 7 -u "$fd" magic
  exec {fd}<&-
  if test "$magic" = $'\041\074arch\076'; then return 0; else return 1; fi
}
