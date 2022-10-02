# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  yt = lib.libyants;

# ---------------------------------------------------------------------------- #

  # Add type chekcers to converters for type classes.
  # Fields of `X' take the form `X.<from>.<to>', e.g.
  #   ytypes = { string, foo, ... };
  #   X.string.this : parse string to `foo' type.
  #   X.this.attrs  : serialize `foo' type.
  #   X.tag.this    : extract `{ foo = ...; }' tag ( see `./tags.nix' ).
  #
  # Example:
  # { lib }: let
  #   ytypes = {
  #     inherit (lib.libyants) string;
  #     foo = foo = with lib.libyants;
  #       restrict "foo" ( lib.test ".*[fF]oo.*" ) string;
  #   };
  #   X = ( defXTypes ytypes ) {
  #     string.foo = str: let
  #       f = lib.yank ".*([Ff]oo).*" str;
  #     in if f == null then "NOPE" else "<${f}>";
  #   };
  # in map builtins.tryEval [
  #      ( X.string.foo "barFooBaz" )
  #      ( X.string.foo "quux" )
  #    ]
  #   ==> [{ success = true;  value = "<Foo>"; }
  #        { success = false; value = false; }]
  defXTypes = ytypes: X: let
    defX = from: to: yt.defun [ytypes.${from} ytypes.${to}] X.${from}.${to};
    proc = { acc, from }: to:
      { acc = acc // { ${to} = ( defX from to ); }; inherit from; };
    forF = from: xts: let
      tos = builtins.attrNames xts;
    in builtins.foldl' proc { acc = {}; inherit from; } tos;
  in builtins.mapAttrs forF X;

# ---------------------------------------------------------------------------- #

in {
  inherit
    defXTypes
  ;
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
