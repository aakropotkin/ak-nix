# ============================================================================ #
#
# Tests for `libencode' functions defined in `lib/encode.nix'.
#
# ---------------------------------------------------------------------------- #

{ lib }: let

  inherit (lib.libenc)
    toBaseDigits
    toBase16 fromBase16
    toBase32 fromBase32
    toBase64 fromBase64
    hexToSri
    algoFromB16Len
  ;

  inherit (lib.ytypes.Strings)
    md5_hash
    sha1_hash   sha1_sri
    sha256_hash sha256_sri
    sha512_hash sha512_sri
  ;

  sha512s = lib.splitString "\n" ( lib.fileContents ./data/sha512s.txt );

  #sha1-b16   = "2346ad27d7568ba9896f1b7da6b5991251debdf2";
  md5-b16    = builtins.hashFile "md5"    ./default.nix;
  sha1-b16   = builtins.hashFile "sha1"   ./default.nix;
  sha256-b16 = builtins.hashFile "sha256" ./default.nix;
  sha512-b16 = builtins.hashFile "sha512" ./default.nix;

  md5-sri    = "md5-sVrTW42PJbm6YJ9He6843A==";
  sha1-sri   = "sha1-oVWx0LwYalqy8tdQFNCm0r5ng7g="; 
  sha256-sri = "sha256-y/0hAE35nPzZ7XcsIA0wPuaWFopkU3f3slx/OTqkT9Q=";
  sha512-sri = "sha512-zl39eQhTMFM9CgIa6AGyLlULiJirY+65DFbVyrdWrv5G2ypuUE767tNqizmQbr54cayjVoPNehAa7KnLhhD2gA==";


# ---------------------------------------------------------------------------- #

  tests = {

# ---------------------------------------------------------------------------- #

    testType_sha1_hash_0 = {
      expr = builtins.tryEval ( sha1_hash sha1-b16 );
      expected = { success = true; value = sha1-b16; };
    };

    # Ensure length checking is enforced.
    testType_sha1_hash_1 = {
      expr = builtins.tryEval ( sha1_hash "${sha1-b16}a" );
      expected = { success = false; value = false; };
    };


# ---------------------------------------------------------------------------- #

    # Ensure length checking is enforced.
    testType_sha256_sri_0 = {
      expr     = sha256_sri.check sha256-sri;
      expected = true;
    };


    testType_sha512_sri_0 = {
      expr     = sha512_sri.check sha512-sri;
      expected = true;
    };

    testType_sha512_sri_1 = {
      expr     = builtins.filter ( s: ! ( sha512_sri.check s ) ) sha512s;
      expected = [];
    };


# ---------------------------------------------------------------------------- #

  };  # End tests


# ---------------------------------------------------------------------------- #

in lib.libdbg.mkTestHarness { name = "test-libenc"; inherit tests; }


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
