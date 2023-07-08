
#include <iostream>
#include <cstdlib>
#include <string>

#include <nix/shared.hh>
#include <nix/eval.hh>
#include <nix/eval-inline.hh>
#include <nix/flake/flake.hh>
#include <nix/store-api.hh>

#include <nlohmann/json.hpp>

  int
main( int argc, char * argv[], char ** envp )
{
  nix::initNix();
  nix::initGC();

  nix::evalSettings.pureEval = false;

  nix::EvalState state( {}, nix::openStore() );

  try
    {
      auto originalRef = parseFlakeRef( argv[1], nix::absPath( "." ) );
      auto resolvedRef = originalRef.resolve( state.store );
    }
  catch( std::exception & e )
    {
      std::cerr << e.what() << std::endl;
      return EXIT_SUCCESS;
    }

  std::cout << resolvedRef.to_string() << std::endl;

  return EXIT_SUCCESS;
}
