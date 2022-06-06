{ lib }:
rec {

  stripCommentsJSONStr = str:
    let inherit (builtins) concatStringsSep filter isString split; in
    concatStringsSep "" ( filter isString ( split "(//[^\n]*)\n" str ) );

  importJSON' = x:
    let (builtins) isAttrs isString fromJSON readFile; in
    if ( isAttrs x ) then x
    else if ( isString x ) then fromJSON x
    else fromJSON ( stripCommentsJSONStr ( readFile x ) );

}
