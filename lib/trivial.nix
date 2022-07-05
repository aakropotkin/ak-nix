{ lib }: let

  inherit (lib)
    versionOlder
    versionAtLeast
    getVersion
  ;

  inherit (builtins)
    compareVersions
    foldl'
  ;


/* -------------------------------------------------------------------------- */

  # If you pass in an attrset you'll receive a list of pairs sorted.
  # Converting back to an attrset would "undo" the sorting because fields are
  # "unsorted" and printed alphabetically.
  sortVersions' = { ascending ? false, accessor ? getVersion }: xs: let
    gvp = if builtins.isList xs then accessor
                                else ( { name, value }: accessor value );
    versionList = if builtins.isList xs then xs else lib.attrsToList xs;
    cmpDesc = a: b: 0 < ( compareVersions ( gvp a ) ( gvp b ) );
    cmpAsc  = a: b: ( compareVersions ( gvp a ) ( gvp b ) ) < 0;
    cmp = if ascending then cmpAsc else cmpDesc;
    sorted = builtins.sort cmp versionList;
  in sorted;

  sortVersions = sortVersions' {};

  # FIXME: `foldl' can optimize this but you need to redeclare the comparitors.
  latestVersion' = xs: builtins.head ( sortVersions xs );
  latestVersion = xs: let
    latest = latestVersion' xs;
  in if builtins.isList xs then latest else { ${latest.name} = latest.value; };


/* -------------------------------------------------------------------------- */

  # Be careful with this, it's easy to exceed 2^64 without realizing it.
  pow' = x: pow: let
    counter = builtins.getList ( _: null ) pow;
  in builtins.foldl' ( acc: _: acc * x ) 1 counter;

  pow = x: pow: let
    _mulSafe = a: b: let c = a * b; in assert ( c != 0 ); c;
    counter = builtins.getList ( _: null ) pow;
    rsl = builtins.foldl' ( acc: _: _mulSafe acc x ) 1 counter;
  in if x == 0 then 0 else rsl;

  mulSafe = a: b: let
    c = a * b;
  in assert ( ( a == 0 ) || ( b == 0 ) ) || ( c != 0 ); c;


/* -------------------------------------------------------------------------- */

  baseListToDec' = base: digits: foldl' ( acc: x: acc * base + x ) 0 digits;
  baseListToDec = base: digits:
    foldl' ( acc: x: ( mulSafe acc base ) + x ) 0 digits;


/* -------------------------------------------------------------------------- */

  # Wrap a routine with `runHook (pre|post)<TYPE>'
  withHooks = type: body: let
    up = let
      u = lib.toUpper ( builtins.substring 0 1 type );
    in u + ( builtins.substring 1 ( builtins.stringLength type ) type );
  in "runHook pre${up}\n${body}\nrunHook post${up}";


/* -------------------------------------------------------------------------- */

  # Inclusive
  semverRange' = { from, to }: let
    x = ( compareVersions to from ) < 0;
  in if x then { from = to; to = from; } else { inherit to from; };

  semverRange = x:
    if builtins.isAttrs x then semverRange' x else
      to: semverRange' { from = x; inherit to; };

  semverInRange = { from, to }: v: let
    f = ( compareVersions from v ) <= 0;
    t = 0 <= ( compareVersions to v );
  in f && t;

  # XXX: Does not assert that the merge is valid.
  semverJoinRanges' = a: b: let
    from = if ( compareVersions a.from b.from ) < 0 then a.from else b.from;
    to = if 0 < ( compareVersions a.to b.to ) then a.to else b.to;
  in { inherit from to; };

  # XXX: Does not assert that the merge is valid.
  semverIntersectRanges' = a: b: let
    from = if ( compareVersions a.from b.from ) < 0 then b.from else a.from;
    to = if 0 < ( compareVersions a.to b.to ) then b.to else a.to;
  in { inherit from to; };

  semverRangesOverlap = a: b: let
    af = semverInRange b a.from;
    at = semverInRange b a.to;
    bf = semverInRange a b.from;
    bt = semverInRange a b.to;
  in af || at || bf || bt;


/* -------------------------------------------------------------------------- */

  semverSatRange = semverInRange;
  semverSatExact = want: have: ( compareVersions want have ) == 0;
  semverSatTilde = want: have: let
    w' = lib.yank "([^-]+)-.*" want;
    h' = lib.yank "([^-]+)-.*" have;
  in ( compareVersions w' h' ) == 0;
  semverSatCaret = want: have: let
    gt = ( compareVersions want have ) <= 0;
    sm = ( lib.versions.major want ) == ( lib.versions.major have );
  in gt && sm;
  semverSatGt  = want: have: ( compareVersions want have ) < 0;
  semverSatGe  = want: have: ( compareVersions want have ) <= 0;
  semverSatLt  = want: have: 0 < ( compareVersions want have );
  semverSatLe  = want: have: 0 <= ( compareVersions want have );
  # FIXME: Join/Intersect ranges
  semverSatAnd = cond1: cond2: have: ( cond1 have ) && ( cond2 have );
  semverSatOr  = cond1: cond2: have: ( cond1 have ) || ( cond2 have );
  semverSatAny = _: true;
  semverSatFail = _: false;


/* -------------------------------------------------------------------------- */

  semverNormalizeOp = op: let
    lop = lib.lower op;
  in if lop == "range" || lop == " - " then "range" else
     if lop == "caret" || lop == "^" then "caret" else
     if lop == "or" || lop == "||" then "or" else
     if lop == "and" || lop == "&&" || lop == ", " then "and" else
     if lop == "exact" || lop == "=" then "exact" else
     if lop == "any" || lop == "*" then  "any" else
     if lop == "fail" then "fail" else
     if lop == "le" || lop == "<=" then "le" else
     if lop == "lt" || lop == "<" then "lt" else
     if lop == "ge" || lop == ">=" then "ge" else
     if lop == "gt" || lop == ">" then "gt" else
     throw "Unrecognized op: ${op}";

  semverOpFn = op: let
    nop = semverNormalizeOp op;
  in if nop == "range" then semverSatRange else
     if nop == "caret" then semverSatCaret else
     if nop == "or"    then semverSatOr    else
     if nop == "and"   then semverSatAnd   else
     if nop == "exact" then semverSatExact else
     if nop == "any"   then semverSatAny   else
     if nop == "fail"  then semverSatFail  else
     if nop == "le"    then semverSatLe    else
     if nop == "lt"    then semverSatLt    else
     if nop == "ge"    then semverSatGe    else
     if nop == "gt"    then semverSatGt    else
     throw "Unrecognized op: ${op}";


/* -------------------------------------------------------------------------- */

  semverConst = {
    op   ? "fail"  # range, or, and, exact, tilde, caret, any, gt, ge, lt, le
  , arg1 ? null
  , arg2 ? null
  , argc ? if arg1 == null then 0 else if arg2 == null then 1 else 2
  , sat  ? semverOpFn op
  }: assert 0 <= argc && argc < 3; {
    inherit sat argc;
    op = semverNormalizeOp op;
    _type = "semverConst";
    __functor = self:
      if self.argc == 0 then self.sat else
      if self.argc == 1 then self.sat self.arg1 else
      self.sat self.arg1 self.arg2;
  } // ( if arg1 != null then { inherit arg1; } else {} )
    // ( if arg2 != null then { inherit arg2; } else {} );

  isSemverConst = x:
    ( builtins.isAttrs x ) && ( ( x._type or null ) == "semverConst" );

  # Check to see if two semver constraints are equivalent.
  # This skips checking `sat' and `__functor' fields, and may consider certain
  # combinations of constrainsts to be equivalent - these checks are a work
  # in progress.
  semverConstsEq = c1: c2: let
    inherit (builtins) isAttrs;
    # Call recrusively on `semverConst' arguments, otherwise regular equality.
    argsEq = a1: a2:
      if ! ( ( isAttrs a1 ) && ( isAttrs a2 ) ) then a1 == a2 else
      if ! ( ( isSemverConst a1 ) && ( isSemverConst a2 ) ) then a1 == a1 else
      semverConstsEq a1 a2;
    # Equality of basic attributes.
    # Args are checked in another routine to handle "equivalent arrangements"
    # of arguments, such as `and'/`or' constrainsts with flipped arguments,
    # ranges vs "and" + "ge" + "le", and chains of "and" constraints.
    # XXX: It may make sense to add a functor `equiv' to various constructors
    # below rather than aggragating a giant set of checks here.
    bAttrsEq = ( c1.op == c2.op ) && ( c1.argc == c2.argc );
    # Basic argument equality
    bArgsEq = ( argsEq c1.arg1 c2.arg1 ) && ( argsEq c1.arg2 c2.arg2 );
  ##   # XXX: The eval cache makes this redundant.
  ##   # swapped args in `and'/`or' is still equivalent
  ##   aoFlipEq =
  ##     ( ( c1.op == "or" ) || ( c1.op == "and" ) ) &&
  ##     ( argsEq c1.arg1 c2.arg2 ) && ( argsEq c1.arg2 c2.arg1 );
  ## in bAttrsEq && ( bArgsEq || aoFlipEq );
  in bAttrsEq && bArgsEq;


  semverConstRange = a: b: let
    sr = semverRange' { from = a; to = b; };
  in semverConst {
    op   = "range";
    arg1 = sr.from;
    arg2 = sr.to;
    argc = 2;
    sat  = semverSatRange;
  };

  semverConstExact = want: semverConst {
    op   = "exact";
    arg1 = want;
    argc = 1;
    sat  = semverSatExact;
  };

  semverConstTilde = want: semverConst {
    op   = "tilde";
    arg1 = want;
    argc = 1;
    sat  = semverSatTilde;
  };

  semverConstCaret = want: semverConst {
    op   = "caret";
    arg1 = want;
    argc = 1;
    sat  = semverSatCaret;
  };

  semverConstGt = want: semverConst {
    op   = "gt";
    arg1 = want;
    argc = 1;
    sat  = semverSatGt;
  };

  semverConstGe = want: semverConst {
    op   = "ge";
    arg1 = want;
    argc = 1;
    sat  = semverSatGe;
  };

  semverConstLt = want: semverConst {
    op   = "lt";
    arg1 = want;
    argc = 1;
    sat  = semverSatLt;
  };

  semverConstLe = want: semverConst {
    op   = "le";
    arg1 = want;
    argc = 1;
    sat  = semverSatLe;
  };

  semverConstAny = semverConst {
    op   = "any";
    argc = 0;
    sat  = semverSatAny;
  };

  semverConstFail = semverConst {
    op   = "fail";
    argc = 0;
    sat  = semverSatFail;
  };


  # FIXME: check for range expressions which can be merged.
  semverConstAnd = const1: const2:
    assert ( const1._type == "semverConst" );
    assert ( const2._type == "semverConst" ); let
      standard = semverConst {
        op   = "and";
        arg1 = const1;
        arg2 = const2;
        argc = 2;
        sat  = semverSatAnd;
      };
      # If either constraint is is always true, eliminate it.
      hasAny  = ( const1.op == "any" ) || ( const2.op == "any" );
      fromAny = if ( const1.op == "any" ) then const2 else const1;
      # If either constraint is is always false, short circuit.
      hasFail = ( const1.op == "fail" ) || ( const2.op == "fail" );
      ## XXX: Eval cache should cover this
      ## Check if the given constraints are redundant
      #hasSame = const1 == const2;
    in if hasAny  then fromAny         else
       if hasFail then semverConstFail else
       #if hasSame then const1          else
       standard;

  # FIXME: check for range constessions which can be merged.
  semverConstOr = const1: const2:
    assert ( const1._type == "semverConst" );
    assert ( const2._type == "semverConst" ); let
      standard = semverConst {
        op   = "or";
        arg1 = const1;
        arg2 = const2;
        argc = 2;
        sat  = semverSatOr;
      };
      # If either constraint is is always true, short circuit.
      hasAny  = ( const1.op == "any" ) || ( const2.op == "any" );
      # If either constraint is is always false, eliminate it.
      hasFail  = ( const1.op == "fail" ) || ( const2.op == "fail" );
      fromFail = if ( const1.op == "fail" ) then const2 else const1;
    in if hasAny  then semverConstAny else
       if hasFail then fromFail       else
       standard;


/* -------------------------------------------------------------------------- */

  semverConstRangeEq = rc: oc: let
    isEqRange = ( oc.op == "range" ) &&
                ( rc.arg1 == oc.arg1 ) && ( rc.arg2l == oc.arg2 );
    ocAndGeLe = ( oc.op == "and" ) &&
                ( oc.arg1.op == "ge" ) && ( oc.arg2.op == "le" ) &&
                ( rc.arg1 == oc.arg1.arg1 ) && ( rc.arg2 == oc.arg2.arg1 );
    ocAndLeGe = ( oc.op == "and" ) &&
                ( oc.arg1.op == "le" ) && ( oc.arg2.op == "ge" ) &&
                ( rc.arg1 == oc.arg2.arg1 ) && ( rc.arg2 == oc.arg1.arg1 );
  in assert rc.op == "range";
      isEqRange || ocAndGeLe || ocAndLeGe;



/* -------------------------------------------------------------------------- */

in {
  inherit
    sortVersions'
    sortVersions
    latestVersion'
    latestVersion
    versionOlder
    versionAtLeast
    getVersion
    pow'
    pow
    mulSafe
    baseListToDec'
    baseListToDec
    withHooks
  ;
  inherit
    semverRange
    semverInRange
    semverJoinRanges'
    semverIntersectRanges'
    semverRangesOverlap
    semverSatRange
    semverSatExact
    semverSatTilde
    semverSatCaret
    semverSatGt
    semverSatGe
    semverSatLt
    semverSatLe
    semverSatAnd
    semverSatOr
    semverSatAny
    semverSatFail
    semverConst
  ;
}
