# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ stdenv, bash, nix, boost, nlohmann_json, pkg-config }: stdenv.mkDerivation {
  pname                 = "NAME";
  version               = "0.1.0";
  src                   = builtins.path { path = ./.; };
  nativeBuildInputs     = [pkg-config];
  buildInputs           = [nix nix.dev boost nlohmann_json];
  propagatedBuildInputs = [bash nix];
  dontConfigure         = true;
  libExt                = stdenv.hostPlatform.extensions.sharedLibrary;
  buildPhase            = ''
    $CXX                                                          \
      -shared                                                     \
      -fPIC                                                       \
      -I${nix.dev}/include                                        \
      -I${boost.dev}/include                                      \
      -I${nlohmann_json}/include                                  \
      -include ${nix.dev}/include/nix/config.h                    \
      $(pkg-config --libs --cflags nix-main nix-store nix-expr)   \
      -o "lib$pname$libExt"                                       \
      ./*.cc                                                      \
    ;
  '';
  installPhase = ''
    mkdir -p "$out/bin" "$out/libexec";
    mv "./lib$pname$libExt" "$out/libexec/lib$pname$libExt";
    cat <<EOF >"$out/bin/$pname"
    #! ${bash}/bin/bash
    # A wrapper around Nix that includes the \`libscrape' plugin.
    # First we add runtime executables to \`PATH', then pass off to Nix.
    for p in \$( <"$out/nix-support/propagated-build-inputs"; ); do
      if [[ -d "\$p/bin" ]]; then PATH="\$PATH:\$p/bin"; fi
    done
    exec "${nix}/bin/nix" --plugin-files "$out/libexec/lib$pname$libExt" "\$@";
    EOF
    chmod +x "$out/bin/$pname";
  '';
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
