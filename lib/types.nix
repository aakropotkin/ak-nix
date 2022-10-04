# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  yt = lib.ytypes // lib.ytypes.Prim // lib.ytypes.Core;

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
    in ( builtins.foldl' proc { acc = {}; inherit from; } tos ).acc;
  in builtins.mapAttrs forF X;


# ---------------------------------------------------------------------------- #

  # As above, but create a single set of "pretty" names as:
  # ytypes = { this.name = "bar"; ... };
  # X      = { this.foo = ...; any.this = ...; quux.this = ...; }
  #   ==> { toFoo = ...; coerceBar = ...; fromQuux = ...; }
  #
  # NOTE: any appearance of `this' in attr names is substituted with
  # `ytypes.this.name', so be sure that's set.
  # NOTE: certain converters are skipped, for example `this.any', since it is
  # kind of non-sensical.
  # The real use case here is to generate `(to|from)(String|Attrs)' and
  # `coerce<NAME>' functions.
  defPrettyXFns = ytypes: X: let
    name = ytypes.this.name;
    tc = from: to: let
      tts = if from == "any" then "coerce${lib.libstr.titleCase name}" else
            "from${lib.libstr.titleCase from}";
      fts = if to == "any" then null else "to${lib.libstr.titleCase to}";
    in if from == "this" then fts else
       if to   == "this" then tts else null;
    defPrettyX = from: to: let
      pn = tc from to;
    in if pn == null then {} else {
      ${pn} = yt.defun [ytypes.${from} ytypes.${to}] X.${from}.${to};
    };
    proc = { acc, from }: to: {
      inherit from; acc = acc // ( defPrettyX from to );
    };
    forF = from: xts: let
      tos = builtins.attrNames xts;
    in ( builtins.foldl' proc { acc = {}; inherit from; } tos ).acc;
    froms = builtins.attrNames X;
  in builtins.foldl' ( acc: from: acc // ( forF from X.${from} ) ) {} froms;


# ---------------------------------------------------------------------------- #

in {
  inherit
    defXTypes
    defPrettyXFns
  ;
}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
