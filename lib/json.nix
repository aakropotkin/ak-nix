# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  # This wipes out any C style comments in JSON files that were written by
  # sub-humans that cannot abide by simple file format specifications.
  # Later this function will be revised to schedule chron jobs which send
  # daily emails to offending projects' authors - recommending various
  # re-education programs they may enroll in.
  importJSON' = file: let
    f = lib.libstr.removeSlashSlashComments ( builtins.readFile file );
  in builtins.fromJSON f;


# ---------------------------------------------------------------------------- #

in {
  inherit
    importJSON'
  ;
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
