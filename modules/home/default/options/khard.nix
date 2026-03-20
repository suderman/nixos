# programs.khard.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.khard;
  inherit (lib) mkIf;
in {
  config = mkIf cfg.enable {
    programs.khard = {
      package = pkgs.unstable.khard;
      settings = {
        general = {
          default_action = "list";
          editor = ["nvim" "-i" "NONE"];
        };
        "contact table" = {
          display = "formatted_name";
          preferred_phone_number_type = ["pref" "cell" "home"];
          preferred_email_address_type = ["pref" "work" "home"];
        };
        vcard.private_objects = ["Jabber" "Skype" "Twitter"];
      };
    };
  };
}
