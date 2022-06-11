args @ { lib, ... }: let

  inherit (builtins) typeOf tryEval mapAttrs toJSON;

# Returns a list of tests which "fail".
# A failed test is one where the evaluated `expr' does not `== expected'.
# Failed tests are listed as attrsets with the original fields plus `result':
#   Ex:  [{ expr = myAdd 1 1; expected = 2; result = 3; ... } ...]
#
# I have made `runner' an argument here in several of my own test dirs
# which default to `lib.runTests' ( refering to the Nixpkgs implementation ).
# However in these templates I have opted to leave the `tests.nix' file to be
# as simple as possible so that it may be processed by a variety of more
# specialized harnesses.
#
# Think of this as a dead simple data file, and process it however you'd
# like elsewhere.
in {

  # Stash our inputs in case we'd like to refer to them later.
  # Think of these as "read-only", since overriding this attribute won't have
  # any effect on the tests themselves.
  inputs = args // { inherit lib; };

  testTrivial = {
    expr = let x = 0; in x;
    expected = 0;
  };

}
