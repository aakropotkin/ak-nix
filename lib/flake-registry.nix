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

  serializeVal = v:
    if ! ( ( builtins.isAttrs v ) && ( v ? __serial ) ) then v else
    if ( v ? __serial ) && ( lib.isFunction v.__serial ) then v.__serial v else
    v.__serial;

  ppVal = v:
    if ! ( v ? __toPretty )  then
      lib.generators.toPretty { allowPrettyValues = true; } ( serializeVal v )
    else if lib.isFunction v.__toPretty then v.__toPretty v
    else v.__toPretty;

  mkIndirectFlakeRef = x: let
    forAttrs = { id, ref ? null, ... } @ ent: {
      _type = "flake-ref";
      type  = "indirect";
      __toString = self:
        if self ? ref then "${self.id}/${self.ref}" else self.id;
      __serial = self: builtins.intersectAttrs {
        type = true;
        id   = true;
        ref  = true;
      } self;
      __toPretty = self: ppVal ( self.__serial self );
      inherit id;
    } // ( lib.optionalAttrs ( ref != null ) { inherit ref; } );
    fromString = let
      m   = builtins.match "([^/]+)(/([^/]+))?" x;
      ref = builtins.elemAt m 2;
    in forAttrs { id = builtins.head m; inherit ref; };
  in assert ( builtins.isAttrs x ) || ( builtins.isString x );
     if builtins.isAttrs x then ( forAttrs x ) else fromString;


  mkFlakeRegistryAlias = { from, to }: {
    _type = "flake-registry-entry";
    __toString = self: "${toString self.from} -> ${toString self.to}";
    __serial = self: {
      from = serializeVal self.from;
      to   = serializeVal self.to;
    };
    __toPretty = self: ppVal ( self.__serial self );
    from  = mkIndirectFlakeRef from;
    to    = mkIndirectFlakeRef to;
  };



# ---------------------------------------------------------------------------- #

in {

  inherit
    mkIndirectFlakeRef
    mkFlakeRegistryAlias
  ;

} // ( lib.optionalAttrs ( ! lib.inPureEvalMode ) {

  inherit
    registries
    registryFlakes
  ;

} )


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
