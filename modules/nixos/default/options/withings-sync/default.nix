{
  config,
  lib,
  flake,
  ...
}: let
  inherit (lib) mkIf;
  enable = flake.lib.anyUser config (user: user.services.withings-sync.enable);
in {
  config = mkIf enable {
    # Access secret with login credentials
    age.secrets.withings-sync = {
      rekeyFile = ./withings-sync.age;
      mode = "440";
      group = "users";
    };
  };
}
