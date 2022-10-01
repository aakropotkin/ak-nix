# ============================================================================ #
#
# Reference Flake Registry in Nix expressions ( Impure ).
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  registries = let
    paths = {
      # NOTE: The global registry may be different if the user provided CLI args
      # or settings in `nix.conf'.
      # This is the default registry.
      global = let
        repo = builtins.fetchTree {
          type = "git";
          url = "https://github.com/NixOS/flake-registry";
        };
      in "${repo}/flake-registry.json";
      system = "${lib.nixEnvVars.NIX_CONF_DIR}/registry.json";
      user   = "${lib.nixEnvVars._NIX_USER_CONF_DIR}/registry.json";
    };
    fileExists = path:
      ( ! lib.inPureEvalMode ) && ( builtins.pathExists path );
    getReg = path: if ! fileExists path then {} else
      builtins.fromJSON ( builtins.readFile path );
  in builtins.mapAttrs ( _: getReg ) paths;


# ---------------------------------------------------------------------------- #

  lookupFlakeIn = { flakes ? [], ... } @ reg: id: let
    flt = builtins.filter ( { from, ... }: from.id == id ) flakes;
  in if ( builtins.length flt ) < 1 then null else builtins.head flt;

  lookupFlake = id: let
    u = lookupFlakeIn registries.user   id;
    s = lookupFlakeIn registries.system id;
    g = lookupFlakeIn registries.global id;
  in if u != null then u else if s != null then s else g;


# ---------------------------------------------------------------------------- #

  registryFlakeRefs = let
    flakes  = ( registries.global.flakes or [] ) ++
              ( registries.system.flakes or [] ) ++
              ( registries.user.flakes or [] );
    asAttrs = { from, to }: {
      name  = if from ? ref then "${from.id}/${from.ref}" else from.id;
      value = to;
    };
  in builtins.listToAttrs ( map asAttrs flakes );

  # The real trees produced by flakes have no indication of `dir' in
  # their fields.
  # The only way you can tell is literally to poke around with `readDir'.
  # Here we just take our original args addin `outPath' and `sourceInfo'.
  #
  # FIXME: follow  indirect -> indirect -> ... -> real
  registryFlakeTrees = let
    # XXX: this preserves `dir' at top level.
    ftf = _: fra: let
      sourceInfo = builtins.fetchTree ( removeAttrs fra ["dir"] );
    in fra // { inherit sourceInfo; inherit (sourceInfo) outPath; };
  in builtins.mapAttrs ftf registryFlakeRefs;


# ---------------------------------------------------------------------------- #

  toValue = x: let
    members = let
      fallback = if x ? val then {} else
        lib.filterAttrs ( k: v: ! ( lib.hasPrefix "__" k ) ) x;
    in x.members or fallback;
    val = x.val or ( lib.mapAttrs ( _: toValue ) members );
  in if ! ( builtins.isAttrs x ) then x else
     if x ? __toValue then x.__toValue x else
     val;


# ---------------------------------------------------------------------------- #

  inherit (lib.generators) toPretty;

# ---------------------------------------------------------------------------- #

  # NOTE: Options have subtypes that can be inferred from their `name' field.
  typeOf = x: let
    fromBuiltin = builtins.typeOf x;
    fromString =
      if lib.isStorePath     then "store-path"          else
      if builtins.hasContext then "string-with-context" else
      fromBuiltin;
    fromAttrs =
      if x ? _type          then x._type      else
      if lib.isDerivation x then "derivation" else
      if lib.isFunction x   then "function"   else  # Distinct from "lambda"
      fromBuiltin;
  in if fromBuiltin == "string" then fromString else
     if fromBuiltin == "set"    then fromAttrs  else
     fromBuiltin;
  

# ---------------------------------------------------------------------------- #

  defToPretty' = {
    _type      ? lib.typeOf attrs
  , __toPretty ?  self: {
      val      = toValue self;
      __pretty = toPretty { allowPrettyValues = true; };
    }
  , ...
  } @ attrs: attrs // { inherit __toPretty _type; };

  defToPretty = {
    # FIXME: fill rest of `__functionMeta'.
    __functionMeta.argTypes = ["anything"];
    __functionArgs = lib.functionArgs defToPretty';
    __functor = self: x:
      if builtins.isAttrs x then defToPretty' x else defToPretty' {
        _type = typeOf x;
        val   = x;
      };
  };


# ---------------------------------------------------------------------------- #

  # FIXME: For options you can use their `show' member function.
  toPrettyV = x:
    if ( x ? __pretty ) && ( x ? val ) then { inherit (x) __pretty val; } else 
    if x ? __toPretty then x.__toPretty x else
    toPrettyV ( defToPretty x );

# ---------------------------------------------------------------------------- #

  mkIndirectFlakeRef = x: let
    fromAttrs = { id, ref ? null, ... } @ ent: defToPretty' {
      _type = "flake-ref";
      __toString = self: let
        v = toValue self;
      in if self ? val.ref then "${v.id}/${v.ref}" else v.id;
      __toValue = self: self.val;
      val = {
        type = "indirect";
        inherit id;
      } // ( lib.optionalAttrs ( ref != null ) { inherit ref; } );
    };
    parse = str: let
      m   = builtins.match "([^/]+)(/([^/]+))?" str;
      ref = builtins.elemAt m 2;
    in fromAttrs { id = builtins.head m; inherit ref; };
  in assert ( builtins.isAttrs x ) || ( builtins.isString x );
     if builtins.isString x then parse x else
     if lib.isType "flake-ref" x then x else
     fromAttrs x;


  mkFlakeRegistryAlias = { from, to }:
    defToPretty' {
      _type      = "flake-registry-entry";
      __toString = self: let
        v = self.members;
      in "${toString v.from} -> ${toString v.to}";
      __toValue  = self: builtins.mapAttrs toValue self.members;
      members.from = mkIndirectFlakeRef from;
      members.to   = mkIndirectFlakeRef to;
    };



# ---------------------------------------------------------------------------- #

in {

  inherit
    toValue
    toPrettyV
    typeOf
    defToPretty

    mkIndirectFlakeRef
    mkFlakeRegistryAlias
  ;

} // ( lib.optionalAttrs ( ! lib.inPureEvalMode ) {

  inherit
    registries
    registryFlakeRefs
    registryFlakeTrees
  ;

} )


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
