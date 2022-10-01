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


# ---------------------------------------------------------------------------- #

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


# ---------------------------------------------------------------------------- #

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


# ---------------------------------------------------------------------------- #

  baseListToDec' = base: digits: foldl' ( acc: x: acc * base + x ) 0 digits;
  baseListToDec = base: digits:
    foldl' ( acc: x: ( mulSafe acc base ) + x ) 0 digits;


# ---------------------------------------------------------------------------- #

  # Wrap a routine with `runHook (pre|post)<TYPE>'
  withHooks = type: body: let
    up = let
      u = lib.toUpper ( builtins.substring 0 1 type );
    in u + ( builtins.substring 1 ( builtins.stringLength type ) type );
  in "runHook pre${up}\n${body}\nrunHook post${up}";


# ---------------------------------------------------------------------------- #

  getEnvOr = fallback: var: let
    val = builtins.getEnv var;
  in if lib.inPureEvalMode then fallback else
     if val == "" then fallback else val;


  nixEnvVars = let
    lookup = var: fb: lib.getEnvOr fb var;
    localstatedir = "/nix/var";
    vars = self:
      builtins.mapAttrs lookup {
        HOME            = "/home-shelter";
        XDG_CONFIG_DIRS = "/etc/xdg";
        XDG_CONFIG_HOME = "${self.HOME}/.config";
        XDG_CACHE_HOME  = "${self.HOME}/.cache";
        NIX_STORE_DIR   = self.NIX_STORE;
        NIX_STORE       = "/nix/store";
        NIX_CONF_DIR    = "/etc/nix";
        # NOTE: searched in reverse order
        NIX_USER_CONF_FILES = builtins.concatStringsSep ":" [
          self.XDG_CONFIG_DIRS
          self.XDG_CONFIG_HOME
        ];
        NIX_CONFIG = "";
        # Legacy `nix-env' CLI uses this
        NIX_PROFILE = "${localstatedir}/nix/profiles/default";
        # Set by Daemon
        NIX_PROFILES = [
          "${localstatedir}/nix/profiles/default"
          "${self.HOME}/.nix-profile"
        ];
        IN_NIX_SHELL = "";
        IN_NIX_REPL  = "";
      };
    vals = ( lib.fix vars ) // {
      # This is made up, I use it for convenience.
      _NIX_USER_CONF_DIR = let
        m = builtins.match "(.*:)?([^:]+)" vals.NIX_USER_CONF_FILES;
      in if m == null then vals.XDG_CONFIG_HOME else builtins.elemAt m 1;
    };
  in if lib.inPureEvalMode then {} else vals;


# ---------------------------------------------------------------------------- #

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
    getEnvOr
    nixEnvVars
  ;
}
