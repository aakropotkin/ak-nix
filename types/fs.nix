# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ ytypes }: let

  lib.test = patt: s: ( builtins.match patt s ) != null;
  yt = ytypes // ytypes.Prim // ytypes.Core;
  inherit (yt) restrict string either eitherN sum;

# ---------------------------------------------------------------------------- #

  RE = {
    evil_filename_c = "[^/\0]";
    evil_path_c     = "[^\0]";

    # NOTE: requires that spaces be escaped
    uri_filename_c = "[:alnum:]%:@&=+$,_.!~*'()-";  # "param" cc
    uri_path_c     = "${RE.uri_filename_c};?/";

    # Sane filename characters for people who weren't raised in barns.
    sane_filename_c = "[:alnum:]_.@~-";
    sane_path_c     = "/${RE.sane_filename_c}";

    filename_c = " ${RE.uri_filename_c}";
    path_c     = " ${RE.uri_path_c}";
  };  # End RE


# ---------------------------------------------------------------------------- #

  # TODO: `realpath'/`logicalpath' ( contains ".." ).
  Strings = {

    filename = let
      charsCond    = lib.test "[${RE.filename_c}]+";
      reservedCond = x: ( x != "." ) && ( x != ".." );
    in restrict "filename" ( x: ( charsCond x ) && ( reservedCond x ) ) string;

    path = restrict "path" ( lib.test "[${RE.path_c}]*" ) string;

    abspath = restrict "absolute" ( lib.test "/.*" )    Strings.path;
    relpath = restrict "relative" ( lib.test "[^/].*" ) Strings.path;

    store_path = restrict "store" ( lib.test "/nix/store/.*" ) Strings.abspath;

  };  # End Strings


# ---------------------------------------------------------------------------- #

  Eithers = {

    abspath = ( either Strings.abspath yt.Prim.path ) // {
      name = "abspath";
      toError = v: result: let
        pv = yt.__internal.prettyPrint v;
        common = "Expected an absolute path ( string or path primitive ), ";
        wrongType =
          common + "but value '${pv}' is of type '${builtins.typeOf v}'.";
        notAbs =
          common + "but pathlike string '${toString v}' is not absolute.";
        cp = Strings.path.checkType v;
      in if ! ( builtins.isString v ) then wrongType else
         if cp.ok then notAbs else cp.err;
    };

    store_path = let
      cond = x: Strings.store_path.check ( toString x );
    in either Strings.store_path ( restrict "store" cond yt.Prim.path );

  };  # End Eithers


# ---------------------------------------------------------------------------- #

  Enums = {

    inode_type = yt.enum "inode:type" [
      "directory" "regular" "symlink" "unknown"
    ];

  };  # End Enums


# ---------------------------------------------------------------------------- #

  FunctionSigs = {

    filter = [Strings.path Enums.inode_type yt.bool];

  };  # End FunctionSigs


# ---------------------------------------------------------------------------- #

in {

  inherit
    RE
    Strings
    Eithers
    FunctionSigs
    Enums
  ;

  inherit (Strings)
    filename
  ;

  inherit (Eithers)
    abspath
    store_path
  ;

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
