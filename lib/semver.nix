# ============================================================================ #
#
# Semantic version range and comparator evaluator, and SAT predicates.
#
# These are divided into three categories of function:
#   1. typeclass constructors:
#      - create range objects, and constraint predicate builders.
#   2. range object and predicate optimization routines:
#      - detect if ranges are inclusive, exclusive, or overlapping.
#      - detect if a range constraint is equivalent to a
#        ( Gt && Lt ) expression.
#      - short circuit `COND && false', `true && COND',
#      - these allow us reduce gramatically distinct but semantically
#        equivalent statements without evaluating the expressions themselves.
#      - TODO: simplify ( Gt && Lt ) to range object.
#   3. "satisfies" predicates for all of the various semver operators.
#      - expressions bottom out to calling these.
#      - the predicates can be run directly, the evaluator is a layer on top.
#
# NOTE: see the test suite for examples of how expressions are constructed.
#
# TODO: you can easily drop dependence on `lib', making this standalone.
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  # Same as default compare except unlike Nix we treat pre-tags as being "lower"
  # than untagged versions.
  # For whatever reason Nix's builtin compare treats "pre-tags" as "newer" than
  # the same untagged version.
  compareSemvers = a: b: let
    base    = builtins.compareVersions a b;
    ma = lib.yank "([^-]+)(-.*)?" a;
    mb = lib.yank "([^-]+)(-.*)?" b;
  in if a == b then 0 else
     if ( a != ma ) && ( b != mb ) then base else
     if ( a == ma ) && ( b == mb ) then base else
     if ( a == mb ) || ( b == ma ) then - base else
     base;

# ---------------------------------------------------------------------------- #

  # Inclusive
  semverRange' = { from, to }: let
    x = ( compareSemvers to from ) < 0;
  in if x then { from = to; to = from; } else { inherit to from; };

  semverRange = x:
    if builtins.isAttrs x then semverRange' x else
      to: semverRange' { from = x; inherit to; };

  semverInRange = { from, to }: v: let
    f = ( compareSemvers from v ) <= 0;
    t = 0 <= ( compareSemvers to v );
  in f && t;

  # XXX: Does not assert that the merge is valid.
  semverJoinRanges' = a: b: let
    from = if ( compareSemvers a.from b.from ) < 0 then a.from else b.from;
    to = if 0 < ( compareSemvers a.to b.to ) then a.to else b.to;
  in { inherit from to; };

  # XXX: Does not assert that the merge is valid.
  semverIntersectRanges' = a: b: let
    from = if ( compareSemvers a.from b.from ) < 0 then b.from else a.from;
    to = if 0 < ( compareSemvers a.to b.to ) then b.to else a.to;
  in { inherit from to; };

  semverRangesOverlap = a: b: let
    af = semverInRange b a.from;
    at = semverInRange b a.to;
    bf = semverInRange a b.from;
    bt = semverInRange a b.to;
  in af || at || bf || bt;


# ---------------------------------------------------------------------------- #

  semverSatRange = semverInRange;

  semverSatExact = want: have: ( compareSemvers want have ) == 0;

  semverSatTilde = want: have: let
    w' = lib.yank "([^-]+)-.*" want;
    w  = if w' == null then want else w';
    h' = lib.yank "([^-]+)-.*" have;
    h  = if h' == null then have else h';
  in ( compareSemvers w h ) == 0;

  # FIXME: `0.x' and `0.0.x' are special cases.
  semverSatCaret = want: have: let
    gt = ( compareSemvers want have ) <= 0;
    sm = ( lib.versions.major want ) == ( lib.versions.major have );
  in gt && sm;

  semverSatGt  = want: have: ( compareSemvers want have ) < 0;
  semverSatGe  = want: have: ( compareSemvers want have ) <= 0;
  semverSatLt  = want: have: 0 < ( compareSemvers want have );
  semverSatLe  = want: have: 0 <= ( compareSemvers want have );

  # FIXME: Join/Intersect ranges
  semverSatAnd  = cond1: cond2: have: ( cond1 have ) && ( cond2 have );
  semverSatOr   = cond1: cond2: have: ( cond1 have ) || ( cond2 have );
  semverSatAny  = _: true;
  semverSatFail = _: false;


# ---------------------------------------------------------------------------- #

  semverOpAliases = {
    range = "range";
    caret = "caret";
    "or"  = "or";
    and   = "and";
    exact = "exact";
    le    = "le";
    lt    = "lt";
    ge    = "ge";
    gt    = "gt";
    any   = "any";
    fail  = "fail";
    " - " = "range";
    "||"  = "or";
    "&&"  = "and";
    ", "  = "and";
    "^"   = "caret";
    "~"   = "tilde";
    "="   = "exact";
    "<="  = "le";
    "=<"  = "le";
    "<"   = "lt";
    "=>"  = "ge";
    ">="  = "ge";
    ">"   = "gt";
    "*"   = "any";
  };

  semverNormalizeOp = op:
    semverOpAliases.${op} or semverOpAliases.${lib.toLower op} or
    ( throw "Unrecognized op: ${op}" );


  semverOpFns = {
    range = semverSatRange;
    caret = semverSatCaret;
    "or"  = semverSatOr;
    and   = semverSatAnd;
    exact = semverSatExact;
    le    = semverSatLe;
    lt    = semverSatLt;
    ge    = semverSatGe;
    gt    = semverSatGt;
    any   = semverSatAny;
    fail  = semverSatFail;
  };

  semverOpFn = op: semverOpFns.${op} or semverOpFns.${semverNormalizeOp op};


# ---------------------------------------------------------------------------- #

  semverConst = {
    op   ? "fail"  # range, or, and, exact, tilde, caret, any, gt, ge, lt, le
  , arg1 ? null
  , arg2 ? null
  , argc ? if arg1 == null then 0 else if arg2 == null then 1 else 2
  , sat  ? semverOpFn op
  } @ args: assert ( 0 <= argc ) && ( argc < 3 ); let
    op' = semverNormalizeOp op;
  in {
    inherit sat argc;
    op = op';
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
    arg1 = sr;
    argc = 1;
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

  # FIXME: check for range consts which can be merged.
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


# ---------------------------------------------------------------------------- #

  semverConstRangeEq = rc: oc: let
    isEqRange = ( oc.op == "range" ) && ( rc.arg1 == oc.arg1 );
    ocAndGeLe = ( oc.op == "and" ) &&
                ( oc.arg1.op == "ge" ) && ( oc.arg2.op == "le" ) &&
                ( rc.arg1.from == oc.arg1.arg1 ) &&
                ( rc.arg1.to   == oc.arg2.arg1 );
    ocAndLeGe = ( oc.op == "and" ) &&
                ( oc.arg1.op == "le" ) && ( oc.arg2.op == "ge" ) &&
                ( rc.arg1.to == oc.arg2.arg1 ) &&
                ( rc.arg1.to == oc.arg1.arg1 );
  in assert rc.op == "range";
     isEqRange || ocAndGeLe || ocAndLeGe;


# ---------------------------------------------------------------------------- #

in {
  inherit
    compareSemvers
    semverRange
    semverInRange
    semverJoinRanges'
    semverIntersectRanges'
    semverRangesOverlap
  ;
  inherit
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
  ;
  inherit
    semverConst
    semverConstsEq
    semverConstRange
    semverConstExact
    semverConstTilde
    semverConstCaret
    semverConstGt
    semverConstGe
    semverConstLt
    semverConstLe
    semverConstAnd
    semverConstOr
    semverConstAny
    semverConstFail

    semverConstRangeEq
    semverOpFn
  ;

}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
