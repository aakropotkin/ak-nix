#include "nix/config.hh"
#include "nix/primops.hh"

using namespace nix;

  static void
prim_hello( EvalState & state, const Pos & pos, Value ** args, Value & v )
{
  v.mkString( "Hello, World!" );
}

static RegisterPrimOp rp( "hello", 0, prim_hello );
