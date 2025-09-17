{
  config,
  lib,
  flake,
  ...
}: let
  inherit (flake.lib) homeService;
  inherit (lib) mkIf;
in {
  config = mkIf (homeService config "withings-sync") {
    # Access secret with login credentials
    age.secrets.withings-sync = {
      rekeyFile = ./withings-sync.age;
      mode = "440";
      group = "users";
    };
  };
}
