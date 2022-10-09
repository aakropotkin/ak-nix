# ============================================================================ #
#
# These helpers were graciously expropriated from
# The Virus Lounge: https://code.tvl.fyi/tree
#
# ---------------------------------------------------------------------------- #
#
# The MIT License (MIT)
#
# Copyright (c) 2019 Vincent Ambo
# Copyright (c) 2020-2021 The TVL Authors
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#
# ---------------------------------------------------------------------------- #

{ lib }: let

# ---------------------------------------------------------------------------- #

  # Takes a tag, checks whether it is an attrset with one element,
  # if so sets `isTag` to `true` and sets the name and value.
  # If not, sets `isTag` to `false` and sets `errmsg`.
  verifyTag = tag:
    let
      cases = builtins.attrNames tag;
      len = builtins.length cases;
    in
    if builtins.length cases == 1
    then
      let name = builtins.head cases; in {
        isTag = true;
        name = name;
        val = tag.${name};
        errmsg = null;
      }
    else {
      isTag = false;
      errmsg =
        ("match: an instance of a sum is an attrset "
          + "with exactly one element, yours had ${toString len}"
          + ", namely: ${lib.generators.toPretty {} cases}");
      name = null;
      val = null;
    };

  # Returns the tag name of a given tag attribute set.
  # Throws if the tag is invalid.
  #
  # Type: tag -> string
  tagName = tag: (assertIsTag tag).name;

  # Returns the tagged value of a given tag attribute set.
  # Throws if the tag is invalid.
  #
  # Type: tag -> any
  tagValue = tag: (assertIsTag tag).val;

  # like `verifyTag`, but throws the error message if it is not a tag.
  assertIsTag = tag: let
    res = verifyTag tag;
  in if res.isTag then { inherit (res) name val; } else throw res.errmsg;


# ---------------------------------------------------------------------------- #

  # Discriminator for values.
  # Goes through a list of tagged predicates `{ <tag> = <pred>; }`
  # and returns the value inside the tag
  # for which the first predicate applies, `{ <tag> = v; }`.
  # They can then later be matched on with `match`.
  #
  # `defTag` is the tag that is assigned if there is no match.
  #
  # Examples:
  #   discrDef "smol" [
  #     { biggerFive = i: i > 5; }
  #     { negative = i: i < 0; }
  #   ] (-100)
  #   => { negative = -100; }
  #   discrDef "smol" [
  #     { biggerFive = i: i > 5; }
  #     { negative = i: i < 0; }
  #   ] 1
  #   => { smol = 1; }
  discrDef = defTag: fs: v: let
    res = lib.findFirst ( t: t.val v ) null ( map assertIsTag fs );
  in if res == null then { ${defTag} = v; } else { ${res.name} = v; };

  # Like `discrDef', but fail if there is no match.
  # NOTE: the original routine used `res != null', however this is a bug.
  # Because `null' is used as a key as `let k = null; in { ${k} = 1; }' you
  # get back an empty set `{}'.
  # I was surprised that this didn't throw an error honestly.
  # XXX: if this ever misbehaves the default should just be swapped for a magic
  # reserved keyword like `"_%FAIL%_"' to avoid undefined behavior.
  discr = fs: v: let
    res = discrDef null fs v;
    msg = "tag.discr: No predicate found that matches " +
          ( lib.generators.toPretty {} v );
  in if res != {} then res else throw msg;


# ---------------------------------------------------------------------------- #

  # The canonical pattern matching primitive.
  # A sum value is an attribute set with one element,
  # whose key is the name of the variant and
  # whose value is the content of the variant.
  # `matcher` is an attribute set which enumerates
  # all possible variants as keys and provides a function
  # which handles each variant’s content.
  # You should make an effort to return values of the same
  # type in your matcher, or new sums.
  #
  # Example:
  #   let
  #      success = { res = 42; };
  #      failure = { err = "no answer"; };
  #      matcher = {
  #        res = i: i + 1;
  #        err = _: 0;
  #      };
  #    in
  #       match success matcher == 43
  #    && match failure matcher == 0;
  #
  match = sum: matcher:
    let cases = builtins.attrNames sum;
    in assert
    let len = builtins.length cases; in
    lib.assertMsg (len == 1)
      ("match: an instance of a sum in an attrset "
        + "with exactly one element, yours had ${toString len}"
        + ", namely: ${lib.generators.toPretty {} cases}");
    let case = builtins.head cases;
    in assert
    lib.assertMsg (matcher ? ${case})
      ("match: \"${case}\" is not a valid case of this sum, "
        + "the matcher accepts: ${lib.generators.toPretty {}
            (builtins.attrNames matcher)}");
    matcher.${case} sum.${case};


# ---------------------------------------------------------------------------- #

  # A `match` with the arguments flipped.
  # “Lam” stands for “lambda”, because it can be used like the
  # `\case` LambdaCase statement in Haskell, to create a curried
  # “matcher” function ready to take a value.
  #
  # Example:
  #   lib.pipe { foo = 42; } [
  #     (matchLam {
  #       foo = i: if i < 23 then { small = i; } else { big = i; };
  #       bar = _: { small = 5; };
  #     })
  #     (matchLam {
  #       small = i: "yay it was small";
  #       big = i: "whoo it was big!";
  #     })
  #   ]
  #   => "whoo it was big!";
  matchLam = matcher: sum: match sum matcher;


# ---------------------------------------------------------------------------- #
 
in
{
  inherit
    verifyTag
    tagName
    tagValue
    discr
    discrDef
    match
    matchLam
  ;
  matchTag = match;
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
