{ libfs ? import ./filesystem.nix }:
let
  # nix build nixpkgs#legacyPackages.x86_64-{linux,darwin}.pkgs{,Static}.stdenv.cc{.bintools.bintools_bin,}
  # NOTE: Musl binaries are named `${stdenv.hostPlatform.config}-${name}'
  stdenvTools = stdenv:
    let
      inherit (stdenv.hostPlatform) isMusl isLinux isDarwin config;
      getTool' = dir: name:
        if isMusl then "${dir}/${config}-${name}" else "${dir}/${name}";
      getTool = dir: name: let t = getTool' dir name; in
        assert ( libfs.exists t );
        t;
      ccp = stdenv.cc;
      btp = stdenv.cc.bintools.bintools_bin;
      getCcTool = getTool "${ccp}/bin";
      getBtTool = getTool "${btp}/bin";
    in {
    # Compiler Collection (stdenv.cc)
    cc  = getCcTool "cc";
    cxx = getCcTool "c++";
    # # Optionals
    # cpp = null;      # Non-Musl
    # gcc = null;      # Linux
    # gxx = null;      # Linux
    # clang = null;    # Darwin
    # clangxx = null;  # Darwin

    # Bintools Collection (stenv.cc.bintools.bintools_bin)
    ar = getBtTool "ar";
    as = getBtTool "as";
    cxxfilt = getBtTool "c++filt";
    ld = getBtTool "ld";
    nm = getBtTool "nm";
    ranlib = getBtTool "ranlib";
    size = getBtTool "size";
    strings = getBtTool "strings";
    strip = getBtTool "strip";
    # # Optionals
    # addr2line = null;          # Linux Only
    # dwp = null;                # Linux Only
    # elfedit = null;            # Linux Only
    # gprof = null;              # Linux Only
    # ldBfd = null;              # Linux Only. Usually the same as `ld'
    # ldGold = null;             # Linux Only
    # objcopy = null;            # Linux Only
    # objdump = null;            # Linux Only
    # readelf = null;            # Linux Only
    # codesign_allocate = null;  # Darwin Only
    # dsymutil = null;           # Darwin Only
    # install_name_tool = null;  # Darwin Only
    # lipo = null;               # Darwin Only
    # otool = null;              # Darwin Only
  };
in {
  inherit stdenvTools;
}
