{ pkgs   ? import <nixpkgs> {}
, stdenv ? pkgs.stdenv
, nix    ? pkgs.nix
, boost  ? pkgs.boost
}: stdenv.mkDerivation {
  pname   = "nix-hello-plugin";
  version = "0.0.1";
  src = builtins.path {
    name = "source";
    path = ./.;
    filter = name: type:
      ( type == "regular" ) && ( ( baseNameOf name ) == "hello.cc" );
  };
  buildInputs = [nix.dev boost.dev];
  buildPhase = ''
    runHook preBuild
    g++ -shared -o libhello.so -g -std=c++17 ./hello.cc
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/libexec
    mv -- ./libhello.so $out/libexec/libhello.so
    runHook postInstall
  '';
}
/**
 * nix --option plugin-files './result/libexec/libhello.so' eval --expr 'hello'
 *   "Hello, World!"
 */
