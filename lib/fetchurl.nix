# Yanked from Nix's internal `src/libexpr/fetchurl.nix'
let
  dropArExt = n: let
    m = builtins.match "(.*)\\.(tar|gz|tgz|zip|xz|bz|tar\\.gz|tar\\.xz|bzip)" n;
  in if m == null then n else builtins.head m;
in
{ url
, hash ? "" # an SRI hash

# Legacy hash specification
, md5    ? ""
, sha1   ? ""
, sha256 ? ""
, sha512 ? ""

, outputHash ?
    if hash   != "" then hash   else
    if sha512 != "" then sha512 else
    if sha1   != "" then sha1   else
    if md5    != "" then md5    else
    sha256
, outputHashAlgo ?
    if hash   != "" then ""       else
    if sha512 != "" then "sha512" else
    if sha1   != "" then "sha1"   else
    if md5    != "" then "md5"    else
    "sha256"

, executable ? false
, unpack     ? false
, name       ? let b = baseNameOf ( toString url ); in
               if unpack then dropArExt b else b

# DISABLED:
### By default, this will prefetch to fill missing hashes.
### presumably if you called this function it's because you actually care about
### having properly formed derivations - it's unlikely that you're going to use
### this over `builtins.fetchurl' "just for kicks".
### Additional options for "impure mode" are given below which may be useful for
### rewrites and avoiding duplicate derivations.
##, pure ? ( builtins ? currentTime )
##
### Context:
### Even when "content addressed" and "fixed output" derivations are being formed,
### using different `outputHashAlgo' types will create duplicate tarballs in the
### nix store, and cause duplicate/redundant branches of anything which depends
### on them.
###
### I know this sounds surprising, I was had trouble believing that this was the
### expected behavior - especially for CA derivations.
### Eeelco confirmed ( June 2022, Nix v2.9 "latest" ATOW ) that this is the
### expected behavior, and that it required to enforce each algo's level of
### strictness - without them being different derivations a very old SHA1 output
### could be passed between Nix stores without ever having stricter SHA checks
### being rerun.
###
### This quirk likely needs more visibility, but for our purposes it leads to a
### major practical side effect for mixing pure and impure derivations that the
### tarball-ttl caching system "subverts" by intentionally keeping these things
### out of the Nix store altogether.
###
### The option below allows you to enforce a specific hash algo in impure mode,
### even if it differs from the provided arguments.
### This prefetches using the provided hash, calculates SHA, and refetches with
### as a real derivation.
##, forceSha256 ? pure

, extraAttrs    ? {}
, extraDrvAttrs ? {}
}: derivation ( {
  inherit name url executable unpack outputHashAlgo outputHash;
  builder = "builtin:fetchurl";
  outputHashMode = if ( unpack || executable ) then "recursive" else "flat";
  system = "builtin";
  # No need to double the amount of network traffic
  preferLocalBuild = true;
  impureEnvVars = [
    # We borrow these environment variables from the caller to allow
    # easy proxy configuration.
    # This is impure, but a fixed-output derivation like fetchurl is allowed to
    # do so since its result is by definition pure.
    "http_proxy" "https_proxy" "ftp_proxy" "all_proxy" "no_proxy"
  ];
  # To make "nix-prefetch-url" work.
  urls = [url];
} // extraDrvAttrs ) // extraAttrs
