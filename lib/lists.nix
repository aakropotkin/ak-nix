# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  inherit (lib) take drop reverseList;

# ---------------------------------------------------------------------------- #

 # This could also be done with a functor:
 #   let adder = { x = 0; __functor = self: x: self // { x = self.x + x; }; };
 #   in ( builtins.foldl' ( acc: acc ) adder [1 2 3] ).rsl
  takeUntil = cond: lst: let
    proc = { rsl, done } @ acc: x:
      if acc.done then acc else
      if cond x   then acc // { done = true; } else
      acc // { rsl = rsl ++ [x]; };
  in ( builtins.foldl' proc { done = false; rsl = []; } lst ).rsl;


  dropAfter = cond: lst: let
    proc = { rsl, done } @ acc: x:
      if done then acc else
      if cond x then { rsl = rsl ++ [x]; done = true; } else
      { rsl = rsl ++ [x]; done = false; };
  in ( builtins.foldl' proc { rsl = []; done = false; } lst ).rsl;


# ---------------------------------------------------------------------------- #

  dropUntil = cond: lst: let
    proc = { rsl, start } @ acc: x:
      if start   then acc // { rsl = rsl ++ [x]; } else
      if cond x then { start = true; rsl = [x]; }  else
      acc;
  in ( builtins.foldl' proc { start = false; rsl = []; } lst ).rsl;


  takeAfter = cond: lst: let
    rsl = dropUntil cond lst;
  in if rsl == [] then [] else builtins.tail rsl;


# ---------------------------------------------------------------------------- #

  commonPrefix = a: b: let
    alen    = builtins.length a;
    blen    = builtins.length b;
    maxLen  = if alen < blen then alen else blen;
    a'      = take maxLen a;
    b'      = take maxLen b;
    idxList = builtins.genList ( x: x ) maxLen;
    proc    = i: ( builtins.elemAt a' i ) != ( builtins.elemAt b' i );
    commons = takeUntil proc idxList;
  in take ( builtins.length commons ) a';


  commonSuffix = a: b:
    reverseList ( commonPrefix ( reverseList a ) ( reverseList b ) );


# ---------------------------------------------------------------------------- #

  # Map Non-Nulls
  mapNoNulls = f: xs:
    map f ( x: builtins.filter ( x != null ) xs );

  # Sieve Non-Nulls from Mapped
  mapDropNulls = f: xs:
    builtins.filter ( x: x != null ) ( map f xs );


# ---------------------------------------------------------------------------- #

in  {
  inherit
    takeUntil
    dropAfter
    dropUntil
    takeAfter
    commonPrefix
    commonSuffix
    mapNoNulls
    mapDropNulls
  ;
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
