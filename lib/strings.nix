# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  base16Chars' = "012345679abcdef";
  base16Chars = "012345679abcdefABCDEF";
  # Omitted: E O U T
  base32Chars' = "0123456789abcdfghijklmnpqrsvwxyz";
  base32Chars  = "0123456789abcdfghijklmnpqrsvwxyzABCDFGHIJKLMNPQRSVWXYZ";

  base64Chars' = "ABCDFGHIJKLMNPQRSVWXYZabcdfghijklmnpqrsvwxyz0123456789+/";
  base64Chars  = "ABCDFGHIJKLMNPQRSVWXYZabcdfghijklmnpqrsvwxyz0123456789+/=";

  isBase16Str = str: ( builtins.match "[${base16Chars}]+" str ) != null;
  isBase32Str = str: ( builtins.match "[${base32Chars}]+" str ) != null;
  isBase64Str = str: ( builtins.match "[A-Za-z0-9\\+/=]+" str ) != null;


# ---------------------------------------------------------------------------- #

  # (Pred) Does `str' match `patt'?
  test = patt: str: ( builtins.match patt str ) != null;

  # Return the N'th capture group, or crash and burn.
  yankN' = n: patt: str: builtins.elemAt ( builtins.match patt str ) n;
  # Return the first capture group, or crash and burn.
  yank' = patt: str: builtins.head ( builtins.match patt str );
  # Return capture groups with indexes in `ns', or crash and burn.
  yankNs' = ns: patt: str:
    map ( builtins.elemAt ( builtins.match patt str ) ) ns;

  # Yankers which fallback to `null' on failure.
  yankN = n: patt: str: let
    m = builtins.match patt str;
  in if m == null then null else builtins.elemAt m n;
  yank = patt: str: let
    m = builtins.match patt str;
  in if m == null then null else builtins.head m;
  yankNs = ns: patt: str: let
    m = builtins.match patt str;
  in if m == null then null else map ( builtins.elemAt m ) ns;


# ---------------------------------------------------------------------------- #

  trim  = yank "[\t ]*([^\t ].*[^\t ])[\t ]*";
  lines = str: builtins.filter builtins.isString ( builtins.split "\n" str );


# ---------------------------------------------------------------------------- #

  # Force a value to a string.
  coerceString = x: let
    inherit (builtins) toJSON mapAttrs isFunction isAttrs trace typeOf;
    coerceAs = as: toJSON ( mapAttrs ( _: v: coerceString v ) as );
  in if ( lib.strings.isCoercibleToString x ) then ( toString x ) else
     if ( isFunction x ) then "<LAMBDA>" else
     if ( isAttrs x )    then ( coerceAs x ) else
        ( trace "Unable to stringify type ${typeOf x}" "<???>" );


# ---------------------------------------------------------------------------- #

  # Get character at index `n'.
  charN' = n: builtins.substring n 1;

  # Get character at index `n', wrapping if out of bounds.
  # charN 1 "hey"       ==> "h"
  # charN ( -1 ) "hey"  ==> "y"
  charN = n: str: let
    len = builtins.stringLength str;
    n' = lib.mod ( n + len ) len;
  in charN' n' str;


# ---------------------------------------------------------------------------- #

  pattHasCaret  = patt: ( charN' 1 patt ) == "^";
  pattHasDollar = patt: ( charN ( -1 ) patt ) == "$";

  # Create a `grep' style matcher from `patt'.
  pattForLine = patt: let
    pre  = if pattHasCaret  patt then "" else "^.*";
    post = if pattHasDollar patt then "" else ".*$";
  in pre + patt + post;

  matchingLines = re: lines: builtins.filter ( test re ) lines;
  linesInfix    = re: lines: builtins.filter ( l: lib.hasInfix re l ) lines;
  readLines     = f: lib.splitString "\n" ( lib.fileContents f );

  linesGrep     = re: lines: matchingLines ( pattForLine re ) lines;
  readLinesGrep = re: f: linesGrep re ( readLines f );
  readGrep      = re: f: builtins.concatStringsSep "\n" ( readLinesGrep re f );


# ---------------------------------------------------------------------------- #

  applyToLines = f: x: let
    inherit (builtins) isString isPath isList concatStringsSep readFile;
    _lines = str: builtins.filter builtins.isString ( builtins.split "\n" str );
    asList = if ( isList x ) then x
      else if ( isString x ) then _lines x
      else if ( isPath x )   then lib.readLines x
      else throw ( "Cannot convert type ${builtins.typeOf x} to a list" +
                    " of strings" );
  in lib.concatMapStringsSep "\n" f asList;


# ---------------------------------------------------------------------------- #

  removeSlashSlashComment' = line:
    let ms = builtins.match "([^\"]*(\"[^\"]*\")*[^\"]*[^\\\"])//.*" line;
    in if ( ms == null ) then line else ( builtins.head ms );

  removePoundComment' = line:
    let ms = builtins.match "([^\"]*(\"[^\"]*\")*[^\"]*[^\\\"])#.*" line;
    in if ( ms == null ) then line else ( builtins.head ms );

  removeSlashSlashComments = applyToLines removeSlashSlashComment';
  removePoundComments = applyToLines removePoundComment';


# ---------------------------------------------------------------------------- #

  # Count the number of matches in a string.
  countMatches = splitter: string:
    let inherit (builtins) length split filter isList; in
    length ( filter isList ( split splitter string ) );


# ---------------------------------------------------------------------------- #

  # Return the longest common prefix for strings `a' and `b'.
  commonPrefix = a: b: let
    l = lib.strings.commonPrefixLength a b;
  in builtins.substring 0 l a;

  # Return the longest common suffix for strings `a' and `b'.
  commonSuffix = a: b: let
    l = lib.strings.commonSuffixLength a b;
  in builtins.substring ( l - 1 ) ( builtins.stringLength a ) a;


# ---------------------------------------------------------------------------- #

in {

  inherit (lib)
    splitString
    hasPrefix
    hasSuffix
    hasInfix
    fileContents
  ;

  inherit (lib.strings)
    commonPrefixLength
    commonSuffixLength
  ;

  inherit
    base16Chars'
    base16Chars
    base32Chars'
    base32Chars
    base64Chars'
    base64Chars
    isBase16Str
    isBase32Str
    isBase64Str
    yankN'
    yank'
    yankNs'
    yankN
    yank
    yankNs
    coerceString
    charN
    countMatches
    test
    commonPrefix
    commonSuffix
    matchingLines
    linesInfix
    readLines
    linesGrep
    readLinesGrep
    readGrep
    trim
    lines
  ;

  inherit
    applyToLines
    removeSlashSlashComment'
    removeSlashSlashComments
    removePoundComments'
    removePoundComments
  ;

}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
