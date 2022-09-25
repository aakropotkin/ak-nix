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
      system = "/etc/nix/registry.json";
      user   = "${builtins.getEnv "HOME"}/.config/nix/registry.json";
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

  registryFlakes = let
    asAttrs = { from, to }: { name = from.id; value = to; };
    flakes  = ( registries.global.flakes or [] ) ++
              ( registries.system.flakes or [] ) ++
              ( registries.user.flakes or [] );
  in builtins.listToAttrs ( map asAttrs flakes );


# ---------------------------------------------------------------------------- #

  toValue = x:
    if ! ( builtins.isAttrs x ) then x else
    if x ? __toValue then x.__toValue x else
    builtins.mapAttrs toValue x;

  _pp = lib.generators.toPretty { allowPrettyValues = true; };

  toPrettyV = x: let
    val  = toValue x;
    pVal = if ! ( builtins.isAttrs val ) then val else
           builtins.mapAttrs toValue ( builtins.intersectAttrs val x );
  in if ! ( builtins.isAttrs x ) then x else
     if ( x ? __pretty ) && ( x ? val ) then x else
     if x ? __toPretty then x.__toPretty x else x;
  

  mkIndirectFlakeRef = x: let
    fromAttrs = { id, ref ? null, ... } @ ent: {
      _type = "flake-ref";
      __toString = self: let
        v = toValue self;
      in if self ? val.ref then "${v.id}/${v.ref}" else v.id;
      __toValue = self: self.val;
      __pretty = _pp;
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
     if ( x ? _type ) && ( x._type == "flake-ref" ) then x else
     fromAttrs x;


  mkFlakeRegistryAlias = { from, to }: {
    _type = "flake-registry-entry";
    __toString = self: "${toString self.val.from} -> ${toString self.val.to}";
    __toValue  = self: builtins.mapAttrs toValue self.members;
    __toPretty = self: {
      __pretty = _pp;
      val      = builtins.mapAttrs toPrettyV self.members;
    };
    members.from = mkIndirectFlakeRef from;
    members.to   = mkIndirectFlakeRef to;
  };



# ---------------------------------------------------------------------------- #

in {

  inherit
    mkIndirectFlakeRef
    mkFlakeRegistryAlias
  ;

} // ( lib.optionalAttrs ( ! lib.inPureEvalMode ) {

  inherit
    toValue
    toPrettyV
    registries
    registryFlakes
  ;

} )


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
