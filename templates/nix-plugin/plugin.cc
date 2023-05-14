
#include <nix/command.hh>
#include <nix/eval.hh>
#include <nix/eval-cache.hh>
#include <nix/names.hh>
#include <nlohmann/json.hpp>

using namespace nix;
using namespace nix::flake;
using json = nlohmann::json;

class FlakeCommand : virtual Args, public MixFlakeOptions
{
  std::string flakeUrl = ".";

  public:

    FlakeCommand()
      {
        expectArgs( {
          .label = "flake-url",
          .optional = true,
          .handler = { & flakeUrl },
          .completer = { [&]( size_t, std::string_view prefix ) {
            completeFlakeRef( getStore(), prefix );
          } }
        } );
      }

    FlakeRef getFlakeRef()
      {
        return parseFlakeRef( flakeUrl, absPath( "." ) ); //FIXME
      }

    LockedFlake lockFlake()
      {
        return flake::lockFlake( * getEvalState(), getFlakeRef(), lockFlags );
      }

    std::vector<std::string> getFlakesForCompletion() override
      {
        return { flakeUrl };
      }
};

struct CmdName : FlakeCommand {

  bool someOption = false;

  CmdFlakeScrape()
    {
      addFlag( {
        .longName    = "some-option",
        .description = "TODO",
        .handler     = { & someOption, true }
      } );
    }

  std::string description() override
    {
      return "TODO";
    }

  std::string doc() override
    {
      return "TODO";
    }

  void run( nix::ref<nix::Store> store ) override
    {
      evalSettings.enableImportFromDerivation.setDefault( false );

      auto state       = getEvalState();
      auto flake       = std::make_shared<LockedFlake>( lockFlake() );
      auto localSystem = std::string( settings.thisSystem.get() );

      logger->cout( "%s", "TODO" );
    }
};

static auto rScrapeCmd = registerCommand<CmdFlakeScrape>( "NAME" );
