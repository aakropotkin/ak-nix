rec {
  takeUntil = cond: lst:
    let taker = acc: x:  # acc ::= { rsl : list; stop : bool; }
          if acc.stop then acc else
          if ( ! ( cond x ) ) then ( acc // { stop = true; } ) else
          ( acc // { rsl = acc.rsl ++ [x]; } );
    in ( builtins.foldl' taker { stop = false; rsl = []; } lst ).rsl;

  dropAfter = cond: lst:
    let
      rsl = takeUntil cond lst;
      rlen = builtins.length rsl;
      last = builtins.elemAt lst rlen;
    in if ( lst == [] ) then [] else
       if ( rsl == [] ) then [last] else ( rsl ++ [last] );

  dropUntil = cond: lst:
    let dropper = acc: x:  # acc ::= { rsl : list; start : bool; }
          if acc.start then ( acc // { rsl = acc.rsl ++ [x]; } ) else
          if ( cond x ) then { start = true; rsl = [x]; } else
          acc;
    in ( builtins.foldl' dropper { start = false; rsl = []; } lst ).rsl;

  takeAfter = cond: lst:
    let rsl = dropUntil cond lst; in
    if rsl == [] then [] else ( builtins.tail rsl );
}
