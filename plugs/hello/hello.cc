/* ========================================================================== *
 *
 *
 *
 * -------------------------------------------------------------------------- */

#include "nix/primops.hh"

using namespace nix;

/* -------------------------------------------------------------------------- */

static void prim_hello(
    EvalState & state, const PosIdx pos, Value ** args, Value & v
  )
{
    v.mkString( "Hello, World!" );
}


static RegisterPrimOp primop_hello({
    .name = "__hello",
    .args = {},
    .doc = R"(
      Return the string "Hello, World!"
    )",
    .fun = prim_hello,
});


/* -------------------------------------------------------------------------- *
 *
 *
 *
 * ========================================================================== */
