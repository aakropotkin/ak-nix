# This is technically a lib, and is included in `ak-nix.lib.tsconfig',
# but it has been placed here for visibility, since it's more likely to
# be used only when generating typescript packages.
{ lib
, json-lib  ? import ../../lib/json.nix
, paths-lib ? import ../../lib/paths.nix { inherit lib; }
}:
let

  inherit (json-lib) readJSON;
  inherit (paths-lib) isAbspath asAbspath expandGlob;

  merge2TsConfigs = f1: f2:
    let merged = lib.recursiveUpdate ( readJSON f1 ) ( readJSON f2 );
    in builtins.removeAttrs merged ["extends"];

  findExtends = f1:
    let
      estr = (  readJSON f1 ).extends or null;
      abspath = if estr == null then null else ( asAbspath estr );
    in assert ( abspath != null ) -> builtins.pathExists abspath;
      abspath;

  processExtends = f1:
    let ext = findExtends f1;
        extFlat = if ( ext == null ) then null else ( processExtends ext );
    in if ( extFlat == null )
       then ( readJSON f1 )
       # file to be extended must go first, since we are "updating" those
       # fields with the values in file being processed.
       else merge2TsConfigs extFlat f1;


/* -------------------------------------------------------------------------- */
in {
  # FIXME: Process other types of relative paths which may appear in extended
  #        files since these are interpreted as relative to the file where they
  #        originally appear.
  #        paths     ::= Dictionary :: Alias (Glob-String) -> List of Paths
  #        typeRoots ::= List of Paths
  #        files     ::= List of Paths
  #        include   ::= List of Paths
  #        exclude   ::= List of Paths
  #        outDir    ::= Path
  #        baseUrl   ::= Path
  # NOTE: All of these "List of Paths" values may contain POSIX glob patterns
  #       such as `**/*.js', `**/*', `*.js', etc.
  # NOTE: The "Glob-String" use in the `paths' alias is only important if you
  #       are actually trying to perform a rudimentary path resolution; they
  #       are what allows `@tulip/foo --> common/npm/foo' mappings to be
  #       generated with globs.
  #       AFAIK `"paths": { "@tulip/*": ["*"], ... }' is the only one in use.

  # Returns a Nix attribute set representation of a `tsconfig.json' file.
  # All `extends' fields will be processed and must be readable if stated.
  parseTsConfig = processExtends;

  # Process any `extends' fields in a `tsconfig.json' file.
  # Returns a JSON string.
  flattenTsConfig = tscfg: builtins.toJSON ( processExtends tscfg );

  # Process `extends' fields in `tsconfig.json' file, creating a new "flat"
  # config file.
  rewriteTsConfig = orig:
    builtins.toFile "tsconfig.json" ( builtins.toJSON ( processExtends orig ) );
}
