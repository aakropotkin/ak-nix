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

  sha1-b16 = "2346ad27d7568ba9896f1b7da6b5991251debdf2";


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

  };  # End tests


# ---------------------------------------------------------------------------- #

in lib.libdbg.mkTestHarness { name = "test-libenc"; inherit tests; }


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
