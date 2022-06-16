{ lib }:
let

  inherit (lib) hasInfix splitString fileContents;

/* -------------------------------------------------------------------------- */

  base16Chars' = "012345679abcdef";
  base16Chars = "012345679abcdefABCDEF";
  # Omitted: E O U T
  base32Chars' = "0123456789abcdfghijklmnpqrsvwxyz";
  base32Chars  = "0123456789abcdfghijklmnpqrsvwxyzABCDFGHIJKLMNPQRSVWXYZ";

  isBase16Str = str: ( builtins.match "[${base16Chars}]+" str ) != null;
  isBase32Str = str: ( builtins.match "[${base32Chars}]+" str ) != null;


/* -------------------------------------------------------------------------- */

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


/* -------------------------------------------------------------------------- */

  # Force a value to a string.
  coerceString = x: let
    inherit (builtins) toJSON mapAttrs isFunction isAttrs trace typeOf;
    coerceAs = as: toJSON ( mapAttrs ( _: v: coerceString v ) as );
  in if ( lib.strings.isCoercibleToString x ) then ( toString x ) else
     if ( isFunction x ) then "<LAMBDA>" else
     if ( isAttrs x )    then ( coerceAs x ) else
        ( trace "Unable to stringify type ${typeOf x}" "<???>" );


/* -------------------------------------------------------------------------- */

  # Get character at index `n'.
  charN' = n: builtins.substring n ( n + 1 );

  # Get character at index `n', wrapping if out of bounds.
  # charN 1 "hey"       ==> "h"
  # charN ( -1 ) "hey"  ==> "y"
  charN = n: str: let
    len = builtins.stringLength str;
    n' = lib.mod ( n + len ) len;
  in charN' n' str;


/* -------------------------------------------------------------------------- */

  pattHasCaret  = patt: ( charN' 1 patt ) == "^";
  pattHasDollar = patt: ( charN ( -1 ) patt ) == "$";

  # Create a `grep' style matcher from `patt'.
  pattForLine = patt: let
    pre  = if pattHasCaret  patt then "" else "^.*";
    post = if pattHasDollar patt then "" else ".*$";
  in pre + patt + post;

  matchingLines = re: lines: builtins.filter ( test re ) lines;
  linesInfix    = re: lines: builtins.filter ( l: hasInfix re l ) lines;
  readLines     = f: splitString "\n" ( fileContents f );

  linesGrep     = re: lines: matchingLines ( pattForLine re ) lines;
  readLinesGrep = re: f: linesGrep re ( readLines f );
  readGrep      = re: f: builtins.concatStringsSep "\n" ( readLinesGrep re f );


/* -------------------------------------------------------------------------- */

  # Count the number of matches in a string.
  count = splitter: string:
    let inherit (builtins) length split filter isList; in
    length ( filter isList ( split splitter string ) );


/* -------------------------------------------------------------------------- */

  # Return the longest common prefix for strings `a' and `b'.
  commonPrefix = a: b: let
    l = lib.strings.commonPrefixLength a b;
  in builtins.substring 0 l a;

  # Return the longest common suffix for strings `a' and `b'.
  commonSuffix = a: b: let
    l = lib.strings.commonSuffixLength a b;
  in builtins.substring ( l - 1 ) ( builtins.stringLength a ) a;


/* -------------------------------------------------------------------------- */

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
    isBase16Str
    isBase32Str
    yankN'
    yank'
    yankNs'
    yankN
    yank
    yankNs
    coerceString
    charN
    count
    test
    commonPrefix
    commonSuffix
    matchingLines
    linesInfix
    readLines
    linesGrep
    readLinesGrep
    readGrep
  ;

}
