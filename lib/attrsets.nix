/* ========================================================================== */

{ flake-utils ? builtins.getFlake "github:numtide/flake-utils" }:

rec {

/* -------------------------------------------------------------------------- */

  /* Forward some `flake-utils.lib' definitions.
  inherit (flake-utils.lib) eachSystemMap defaultSystems allSystems;


/* -------------------------------------------------------------------------- */

  /* Create an attrset mapping default system names values returned by `f'.
   *
   * ::= fn -> AttrSet
   * 
   * Example:
   *   packages = eachDefaultSystemMap ( system:
   *     let pkgsFor = import nixpkgs { inherit system; };
   *     in rec {
   *       foo     = pkgsFor.callPackage ./foo.nix {};
   *       bar     = pkgsFor.callPackage ./bar.nix {};
   *       default = foo;
   *     } );
   *   ===>
   *   {
   *     packages.aarch64-linux.foo = <drv>;
   *     packages.aarch64-linux.bar = <drv>;
   *     packages.aarch64-linux.default = <drv>;
   *     packages.aarch64-darwin.foo = <drv>;
   *     packages.aarch64-darwin.bar = <drv>;
   *     packages.aarch64-darwin.default = <drv>;
   *     packages.i686-linux.foo = <drv>;
   *     packages.i686-linux.bar = <drv>;
   *     packages.i686-linux.default = <drv>;
   *     packages.x86_64-darwin.foo = <drv>;
   *     packages.x86_64-darwin.bar = <drv>;
   *     packages.x86_64-darwin.default = <drv>;
   *     packages.x86_64-linux.foo = <drv>;
   *     packages.x86_64-linux.bar = <drv>;
   *     packages.x86_64-linux.default = <drv>;
   *   }
   */
  defaultSystemsMap = f: eachSystemMap defaultSystems f;


/* -------------------------------------------------------------------------- */

  /* Like `eachDefaultSystemMap', but for all systems
   * See `flake-utils' for full list.
   */
  allSystemsMap = eachSystemMap allSystems;


/* -------------------------------------------------------------------------- */

}  /* End `attrsets.nix' */


/* ========================================================================== */
