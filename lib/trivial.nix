{ lib }: let

  inherit (lib)
    versionOlder
    versionAtLeast
    getVersion
  ;

  inherit (builtins) compareVersions;


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

in {
  inherit
    sortVersions'
    sortVersions
    latestVersion'
    latestVersion
    versionOlder
    versionAtLeast
    getVersion
  ;
}
