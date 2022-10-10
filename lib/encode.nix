{ lib }: let

  yt = lib.ytypes // lib.ytypes.Core // lib.ytypes.Prim;

  inherit (lib.libstr)
    base16Chars'
    base16Chars
    isBase16Str
    base32Chars'
    base32Chars
    isBase32Str
    base64Chars'
    base64Chars
    isBase64Str
  ;
  inherit (lib.libtriv)
    pow'
    pow
    mulSafe
    baseListToDec'
    baseListToDec
  ;
  inherit (lib)
    toBaseDigits
    # toHexString  XXX: Returns capitalized characters.
  ;
  inherit (builtins)
    concatLists
    concatStringsSep
    elemAt
    filter
    genList
    head
    isInt
    isList
    isString
    length
    listToAttrs
    match
    replaceStrings
    split
    stringLength
    substring
  ;


# ---------------------------------------------------------------------------- #

  base16ToDecM = {
    "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4; "5" = 5; "6" = 6; "7" = 7;
    "8" = 8; "9" = 9;
    a = 10; A = 10; b = 11; B = 11; c = 12; C = 12;
    d = 13; D = 13; e = 14; E = 14; f = 15; F = 15;
  };

  # Omitted: E O U T
  base32ToDecM = {
    "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4; "5" = 5; "6" = 6; "7" = 7;
    "8" = 8; "9" = 9;
    a = 10; A = 10; b = 11; B = 11; c = 12; C = 12;
    d = 13; D = 13; f = 14; F = 14; g = 15; G = 15;
    h = 16; H = 16; i = 17; I = 17; j = 18; J = 18;
    k = 19; K = 19; l = 20; L = 20; m = 21; M = 21;
    n = 22; N = 22; p = 23; P = 23; q = 24; Q = 24;
    r = 25; R = 25; s = 26; S = 26; v = 27; V = 27;
    w = 28; W = 28; x = 29; X = 29; y = 30; Y = 30;
    z = 31; Z = 31;
  };

  base64ToDecM = {
    A = 0; B = 1; C = 2; D = 3; E = 4; F = 5; G = 6; H = 7; I = 8; J = 9;
    K = 10; L = 11; M = 12; N = 13; O = 14; P = 15; Q = 16; R = 17; S = 18;
    T = 19; U = 20; V = 21; W = 22; X = 23; Y = 24; Z = 25; a = 26; b = 27;
    c = 28; d = 29; e = 30; f = 31; g = 32; h = 33; i = 34; j = 35; k = 36;
    l = 37; m = 38; n = 39; o = 40; p = 41; q = 42; r = 43; s = 44; t = 45;
    u = 46; v = 47; w = 48; x = 49; y = 50; z = 51;
    "0" = 52; "1" = 53; "2" = 54; "3" = 55; "4" = 56; "5" = 57;
    "6" = 58; "7" = 59; "8" = 60; "9" = 61; "+" = 62; "/" = 63;
  };


# ---------------------------------------------------------------------------- #

  splitDigits = str: concatLists ( filter isList ( split "(.)" str ) );


# ---------------------------------------------------------------------------- #

  toHexDigit = x:
    if x <  10 then toString x else
    if x == 10 then "a" else
    if x == 11 then "b" else
    if x == 12 then "c" else
    if x == 13 then "d" else
    if x == 14 then "e" else
    if x == 15 then "f" else
    throw "Cannot convert ${toString x} to a single base 16 digit";

  toHex = x: lib.toLower ( lib.toHexString x );

  fromHex = str: let
    digits = map ( c: base16ToDecM.${c} ) ( splitDigits str );
  in baseListToDec 16 digits;

  # Aliases
  toBase16Digit = toHexDigit;
  toBase16      = toHex;
  fromBase16    = fromHex;

  padBackTo6l = str: let
    n = 6 - ( lib.mod ( stringLength str ) 6 );
    pad = concatStringsSep "" ( genList ( _: "0" ) n );
  in str + pad;


# ---------------------------------------------------------------------------- #

  toBase32Digit = x:
    if x <  10 then toString x else
    if x == 10 then "a" else
    if x == 11 then "b" else
    if x == 12 then "c" else
    if x == 13 then "d" else
    if x == 14 then "f" else
    if x == 15 then "g" else
    if x == 16 then "h" else
    if x == 17 then "i" else
    if x == 18 then "j" else
    if x == 19 then "k" else
    if x == 20 then "l" else
    if x == 21 then "m" else
    if x == 22 then "n" else
    if x == 23 then "p" else
    if x == 24 then "q" else
    if x == 25 then "r" else
    if x == 26 then "s" else
    if x == 27 then "v" else
    if x == 28 then "w" else
    if x == 29 then "x" else
    if x == 30 then "y" else
    if x == 31 then "z" else
    throw "Cannot convert ${toString x} to a single base 32 digit";

  toBase32 = x: let
    digits = toBaseDigits 32 x;
    chars  = map toBase32Digit digits;
  in concatStringsSep "" chars;


  fromBase32 = str: let
    digits = map ( c: base32ToDecM.${c} ) ( splitDigits str );
  in baseListToDec 32 digits;


# ---------------------------------------------------------------------------- #

  toBase64Digit = x:
    if x ==  0 then "A" else
    if x ==  1 then "B" else
    if x ==  2 then "C" else
    if x ==  3 then "D" else
    if x ==  4 then "E" else
    if x ==  5 then "F" else
    if x ==  6 then "G" else
    if x ==  7 then "H" else
    if x ==  8 then "I" else
    if x ==  9 then "J" else
    if x == 10 then "K" else
    if x == 11 then "L" else
    if x == 12 then "M" else
    if x == 13 then "N" else
    if x == 14 then "O" else
    if x == 15 then "P" else
    if x == 16 then "Q" else
    if x == 17 then "R" else
    if x == 18 then "S" else
    if x == 19 then "T" else
    if x == 20 then "U" else
    if x == 21 then "V" else
    if x == 22 then "W" else
    if x == 23 then "X" else
    if x == 24 then "Y" else
    if x == 25 then "Z" else
    if x == 26 then "a" else
    if x == 27 then "b" else
    if x == 28 then "c" else
    if x == 29 then "d" else
    if x == 30 then "e" else
    if x == 31 then "f" else
    if x == 32 then "g" else
    if x == 33 then "h" else
    if x == 34 then "i" else
    if x == 35 then "j" else
    if x == 36 then "k" else
    if x == 37 then "l" else
    if x == 38 then "m" else
    if x == 39 then "n" else
    if x == 40 then "o" else
    if x == 41 then "p" else
    if x == 42 then "q" else
    if x == 43 then "r" else
    if x == 44 then "s" else
    if x == 45 then "t" else
    if x == 46 then "u" else
    if x == 47 then "v" else
    if x == 48 then "w" else
    if x == 49 then "x" else
    if x == 50 then "y" else
    if x == 51 then "z" else
    if x == 52 then "0" else
    if x == 53 then "1" else
    if x == 54 then "2" else
    if x == 55 then "3" else
    if x == 56 then "4" else
    if x == 57 then "5" else
    if x == 58 then "6" else
    if x == 59 then "7" else
    if x == 60 then "8" else
    if x == 61 then "9" else
    if x == 62 then "+" else
    if x == 63 then "/" else
    throw "Cannot convert ${toString x} to a single base 64 digit";


  # FIXME: Handle "=" and "==" padding
  toBase64 = x: let
    digits = toBaseDigits 64 x;
    chars  = map toBase64Digit digits;
  in concatStringsSep "" chars;


  # FIXME: Handle "=" and "==" padding
  fromBase64 = str: let
    digits = map ( c: base64ToDecM.${c} ) ( splitDigits str );
  in baseListToDec 64 digits;


# ---------------------------------------------------------------------------- #

  # nix hash to-base32 "sha512-T4aL2ZzaILkLGKbxssipYVRs8334PSR9FQzTGftZbc3jIPGkiXXS7qUCh8/q8UWFzxBZQ92dvR0v7+AM9wL2PA=="
  # 0ygc0pp1khfybqxpnfxshsr237qaigixb7qf0m5xv97b2d4y4hf7kbdb7xiklqc2myj8ggqgprnqm31m74b5wd6305vj86skkcqp1jg
  #
  # nix hash to-base16 "sha512-T4aL2ZzaILkLGKbxssipYVRs8334PSR9FQzTGftZbc3jIPGkiXXS7qUCh8/q8UWFzxBZQ92dvR0v7+AM9wL2PA=="
  # 4f868bd99cda20b90b18a6f1b2c8a961546cf37df83d247d150cd319fb596dcde320f1a48975d2eea50287cfeaf14585cf105943dd9dbd1d2fefe00cf702f63c
  #
  # nix hash to-base32 "sha1-G2HAViGQqN/2rjuyzwIAyhMLhtQ="
  # sj30n4ya001czcivmvvdza4h45bc0q8v
  #
  # nix hash to-base16 "sha1-G2HAViGQqN/2rjuyzwIAyhMLhtQ="
  # 1b61c0562190a8dff6ae3bb2cf0200ca130b86d4

  fixupSriPadding = hash: let
    m = match "(.*[^A]A)(AA?)" hash;
    p = replaceStrings ["A"] ["="] ( elemAt m 1 );
  in if m == null then hash else ( head m ) + p;

  algoFromB16Len = hash: let
    len = stringLength hash;
  in if len == 128 then "sha512" else
     if len == 64  then "sha256" else
     if len == 40  then "sha1"   else
     if len == 32  then "md5"    else
     throw "Invalid hash length, cannot guess algo: ${hash}";

  hexToSri = h16: let
    b16l = lib.flatten ( split "(......)" ( padBackTo6l h16 ) );
    b10l = map fromHex ( filter ( x: x != "" ) b16l );
    b64  = concatStringsSep "" ( map toBase64 b10l );
    pad  = fixupSriPadding b64;
    algo = algoFromB16Len h16;
  in "${algo}-${pad}";


# ---------------------------------------------------------------------------- #

  sriFile = algo: file: hexToSri ( builtins.hashFile algo file );
  sri256File = sriFile "sha256";
  sri512File = sriFile "sha512";


# ---------------------------------------------------------------------------- #

  ytypes.Strings = {
    sha1_sri = let
      cond = lib.test "sha1-[${base64Chars'}]+={0,2}";
    in yt.restrict "sha1:sri" cond yt.string;
    # sha256-A3eLarlqN1XPBYBcFPY1yUpfxdhJKvDBjN+vsOAmOoc=
    sha256_sri = let
      cond = lib.test "sha256-[${base64Chars'}]+={0,2}";
    in yt.restrict "sha256:sri" cond yt.string;
    sha512_sri = let
      cond = lib.test "sha512-[${base64Chars'}]+={0,2}";
    in yt.restrict "sha512:sri" cond yt.string;
  };



# ---------------------------------------------------------------------------- #

in {

  inherit
    toBaseDigits
    base16Chars' base16Chars isBase16Str
    base32Chars' base32Chars isBase32Str
    base64Chars' base64Chars isBase64Str
    toHex fromHex
    toBase16 fromBase16
    toBase32 fromBase32
    toBase64 fromBase64
    algoFromB16Len
    hexToSri
    sriFile sri256File sri512File
    ytypes
  ;

}
