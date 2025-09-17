{
  config,
  lib,
  ...
}: let
  inherit (builtins) attrNames any;
  inherit (lib) mkIf;
  # If any home-manager withings-sync is enabled for any user, set this to true
  users = config.home-manager.users or {};
  enable = any (user: users.${user}.services.withings-sync.enable or false) (attrNames users);
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
