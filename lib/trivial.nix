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
  semverRange = { from, to }: let
    x = ( compareVersions to from ) < 0;
  in if x then { from = to; to = from; } else { inherit to from; };

  semverInRange = { from, to }: v: let
    f = ( compareVersions from v ) <= 0;
    t = 0 <= ( compareVersions to v );
  in f && t;

  # Does not assert that the merge is valid.
  semverJoinRanges' = a: b: let
    from = if ( compareVersions a.from b.from ) < 0 then a.from else b.from;
    to = if 0 < ( compareVersions a.to b.to ) then a.to else b.to;
  in { inherit from to; };

  semverRangesOverlap = a: b: let
    af = semverInRange b a.from;
    at = semverInRange b a.to;
    bf = semverInRange a b.from;
    bt = semverInRange a b.to;
  in af || at || bf || bt;


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
    semverRange
    semverInRange
    semverJoinRanges'
    semverRangesOverlap
  ;
}
