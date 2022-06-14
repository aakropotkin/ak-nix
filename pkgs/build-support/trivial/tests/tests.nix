args @ { lib, runCommandNoCC, linkutils, tarutils, ... }: let

  inherit (builtins) typeOf tryEval mapAttrs toJSON readFile toFile;
  inherit (tarutils) runTar tar untar tarcli;
  inherit (linkutils) runLn linkOut linkToPath;

  source = runCommandNoCC "source" {} ''
    mkdir -p $out/sub
    echo "Howdy"   > "$out/a"
    echo "Partner" > "$out/b"
    echo "Nest"    > "$out/sub/c"
  '';

  # Recycled for various calls.
  tarSourceCommonArgs = {
    src = ["a" "b" "sub/c"];
    tarFlagsLate = ["-C" "${source}"];
  };

  # Simplest form, just give relative paths from drv root.
  tarSourceExplicit = tar tarSourceCommonArgs;

  # Overridable form of `tarSourceExplicit'
  tarSourceO = lib.makeOverridable tar tarSourceCommonArgs;

  # This produces an identical list of paths as `tarSourceExplicit'; but shows
  # the processes required to get a "regular" tarball with enties that aren't
  # a complete mess.
  # The point of the case is really to illustrate how much of a pain in the
  # ass it is to use `tar { ... }' programmatically.
  tarSourceTreeWalk = tar {
    src =
      # FIXME: The effort required here to remove directories bad.
      # This needs to be reworked, unforunately `tar' doesn't provide
      # useful flags for handling directory structures.
      # Note that getting pathnames to be written without `./<NAME>' is
      # also an issue that needs attention.
      map ( p: lib.libstr.yank "\\./(.*)"
        ( lib.libpath.realpathRel' "${source}" p ) )
        ( lib.filesystem.listFilesRecursive "${source}" );
    tarFlagsLate = ["-C" "${source}"];
  };

  tarballDrvs = {
    inherit tarSourceTreeWalk;
    inherit tarSourceExplicit;
    inherit tarSourceO;
  };

  ttFileLists = tarballs: let
    inherit (builtins) concatStringsSep;
    listMembers = t: ''
      tar -tf ${t} >> "$out"
    '';
    sep = ''
      echo "***" >> "$out"
    '';
    drv = runCommandNoCC "tarball-files.log" {
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ( concatStringsSep sep ( map listMembers tarballs ) );
  in drv // { meta = { inherit tarballs; }; };

  # We need `rec' because some test piggy back off of others' expressions.
in {

  # Stash our inputs in case we'd like to refer to them later.
  # Think of these as "read-only", since overriding this attribute won't have
  # any effect on the tests themselves.
  inputs = args // {
    inherit lib;
    inherit source ;
    inherit tarSourceCommonArgs;
    inherit ttFileLists;
    inherit tarballDrvs;
  };

/* -------------------------------------------------------------------------- */

  testTrivial = {
    expr = let x = 0; in x;
    expected = 0;
  };


/* -------------------------------------------------------------------------- */

  # Assert that `extraAttrs' do not appear in Derivations.
  # This is important because if they do, a change to meta-data will wrongly
  # trigger rebuilds.
  testExtraAttrs_tar = let extraAttrs = { meta.boy = "howdy"; }; in {
    expr = let pkg = tar ( tarSourceCommonArgs // { inherit extraAttrs; } );
    in { pkg = pkg.meta or {}; drv = pkg.drvAttrs.meta or {}; };
    expected = { pkg.meta.boy = "howdy"; drv = {}; };
  };

  # TODO: runTar
  #testExtraAttrs_tar = let extraAttrs = { meta.boy = "howdy"; }; in {
  #  expr = let pkgTar = tar ( tarSourceCommonArgs // { inherit extraAttrs; } );
  #  in { pkg = pkg.meta or {}; drv = pkg.drvAttrs.meta or {}; };
  #  expected = { pkg.meta.boy = "howdy"; drv = {}; };
  #};

  # TODO: tarcli
  #testExtraAttrs_tar = let extraAttrs = { meta.boy = "howdy"; }; in {
  #  expr = let pkgTar = tar ( tarSourceCommonArgs // { inherit extraAttrs; } );
  #  in { pkg = pkg.meta or {}; drv = pkg.drvAttrs.meta or {}; };
  #  expected = { pkg.meta.boy = "howdy"; drv = {}; };
  #};

  # TODO: untar
  #testExtraAttrs_tar = let extraAttrs = { meta.boy = "howdy"; }; in {
  #  expr = let pkgTar = tar ( tarSourceCommonArgs // { inherit extraAttrs; } );
  #  in { pkg = pkg.meta or {}; drv = pkg.drvAttrs.meta or {}; };
  #  expected = { pkg.meta.boy = "howdy"; drv = {}; };
  #};

  # TODO: linkOut
  #testExtraAttrs_tar = let extraAttrs = { meta.boy = "howdy"; }; in {
  #  expr = let pkgTar = tar ( tarSourceCommonArgs // { inherit extraAttrs; } );
  #  in { pkg = pkg.meta or {}; drv = pkg.drvAttrs.meta or {}; };
  #  expected = { pkg.meta.boy = "howdy"; drv = {}; };
  #};

  # TODO: linkToPath
  #testExtraAttrs_tar = let extraAttrs = { meta.boy = "howdy"; }; in {
  #  expr = let pkgTar = tar ( tarSourceCommonArgs // { inherit extraAttrs; } );
  #  in { pkg = pkg.meta or {}; drv = pkg.drvAttrs.meta or {}; };
  #  expected = { pkg.meta.boy = "howdy"; drv = {}; };
  #};

  # TODO: runLn
  #testExtraAttrs_tar = let extraAttrs = { meta.boy = "howdy"; }; in {
  #  expr = let pkgTar = tar ( tarSourceCommonArgs // { inherit extraAttrs; } );
  #  in { pkg = pkg.meta or {}; drv = pkg.drvAttrs.meta or {}; };
  #  expected = { pkg.meta.boy = "howdy"; drv = {}; };
  #};

/* -------------------------------------------------------------------------- */

  testTar = {
    # We are recycling the work done by global `tarSource*` calls.
    expr =
      readFile ( ttFileLists [tarSourceTreeWalk tarSourceExplicit] ).outPath;
    expected = ''
      a
      b
      sub/c
      ***
      a
      b
      sub/c
    '';
  };


/* -------------------------------------------------------------------------- */

  testTarCli = {
    expr = let
      file = toFile "welcome" "Hello, World!";
      foo = tarcli {
        name = "foo.tar.gz";
        argsList = [{
            c = true;               # Create Archive
            f = "$out";             # Name Archive "$out" ( replaced later )
          } {                       # We split to make sure the `foldl' works
            C = dirOf file;         # Change to directory before archiving
            xform = "s,^[^-]*-,,";  # Strip store path
          }
          ( baseNameOf file )       # Input file, relative to `C' working dir
        ];
      };
      # Now unpack it to make sure it did what we wanted.
      unpacked = untar { tarball = foo.outPath; };
      # Confirm the file name was preserved
      # Also, we obviously expect the message to be the same.
    in readFile "${unpacked}/welcome";
    expected = "Hello, World!";
  };


/* -------------------------------------------------------------------------- */

}
