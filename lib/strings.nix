{ lib ? ( builtins.getFlake "nixpkgs" ).lib }:
let
  charN' = n: builtins.substring n ( n + 1 );
  # charN 1 "hey"       ==> "h"
  # charN ( -1 ) "hey"  ==> "y"
  charN = n: str:
    let
      len = builtins.stringLength str;
      n' = lib.mod ( n + len ) len;
    in charN' n' str;

  pattHasCaret = patt: ( charN' 1 patt ) == "^";
  pattHasDollar = patt: ( charN ( -1 ) patt ) == "$";

  pattForLine = patt:
    let
      pre = if pattHasCaret patt then "" else "^.*";
      post = if pattHasDollar patt then "" else ".*$";
    in pre + patt + post;

  count = splitter: string:
    let inherit (builtins) length split filter isList; in
    length ( filter isList ( split splitter string ) );

in rec {
  inherit (lib) splitString hasPrefix hasSuffix hasInfix fileContents;
  inherit charN count;

  matchingLines = re: lines:
    builtins.filter ( l: ( builtins.match re l ) != null ) lines;

  linesInfix = re: lines: builtins.filter ( l: hasInfix re l ) lines;

  linesGrep = re: lines: matchingLines ( pattForLine re ) lines;

  readLines = f: splitString "\n" ( fileContents f );

  readGrep' = re: f: linesGrep re ( readLines f );
  readLinesGrep = readGrep';

  readGrep = re: f: builtins.concatStringsSep "\n" ( readGrep' re f );

}
