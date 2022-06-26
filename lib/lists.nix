{ lib }:
rec {

  inherit (lib) take drop reverseList;

/* -------------------------------------------------------------------------- */

/**
 * This could also be done with a functor:
 *   let adder = { x = 0; __functor = self: x: self // { x = self.x + x; }; };
 *   in ( builtins.foldl' ( acc: acc ) adder [1 2 3] ).rsl
 */
  takeUntil = cond: lst:
    let taker = acc: x:  # acc ::= { rsl : list; stop : bool; }
          if acc.stop then acc else
          if ( cond x ) then ( acc // { stop = true; } ) else
          ( acc // { rsl = acc.rsl ++ [x]; } );
    in ( builtins.foldl' taker { stop = false; rsl = []; } lst ).rsl;

  dropAfter = cond: lst:
    let
      rsl = takeUntil cond lst;
      rlen = builtins.length rsl;
      last = builtins.elemAt lst rlen;
    in if ( lst == [] ) then [] else
       if ( rsl == [] ) then [last] else ( rsl ++ [last] );


/* -------------------------------------------------------------------------- */

  dropUntil = cond: lst:
    let dropper = acc: x:  # acc ::= { rsl : list; start : bool; }
          if acc.start then ( acc // { rsl = acc.rsl ++ [x]; } ) else
          if ( cond x ) then { start = true; rsl = [x]; } else
          acc;
    in ( builtins.foldl' dropper { start = false; rsl = []; } lst ).rsl;

  takeAfter = cond: lst:
    let rsl = dropUntil cond lst; in
    if rsl == [] then [] else ( builtins.tail rsl );


/* -------------------------------------------------------------------------- */

  commonPrefix = a: b:
    let
      inherit (builtins) elemAt length genList;
      alen   = length a;
      blen   = length b;
      maxLen = if ( alen < blen ) then alen else blen;
      a' = take maxLen a;
      b' = take maxLen b;
      idxList = genList ( x: x ) maxLen;
      commons = takeUntil ( i: ( elemAt a' i ) != ( elemAt b' i ) ) idxList;
    in take ( length commons ) a';


/* -------------------------------------------------------------------------- */

  commonSuffix = a: b:
    reverseList ( commonPrefix ( reverseList a ) ( reverseList b ) );


/* -------------------------------------------------------------------------- */

  # Map Non-Nulls
  mapC = f: xs: map f ( x: builtins.filter ( x != null ) xs );
  # Sieve Non-Nulls from Mapped
  mapS = f: xs: builtins.filter ( x: x != null ) ( map f xs );


/* -------------------------------------------------------------------------- */

}
