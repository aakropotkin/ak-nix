#include "nix/primops.hh"

using namespace nix;

/* Determine whether the argument is the null value. */
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
      Return the string "Hello, World!". Does not accept arguments.
    )",
    .fun = prim_hello,
});
