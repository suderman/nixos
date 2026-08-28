# programs.hermes-desktop = {enable = true; profile = "june";};
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.hermes-desktop;
  hermes = config.services.hermes-agent;
  inherit (config.lib.hermes-agent) dataDir localProfiles;
  activeProfile = pkgs.writeText "hermes-desktop-active-profile.json" (builtins.toJSON {
    profile = cfg.profile;
  });
  desktopPackage = hermes.package.hermesDesktop.override {
    extraEnv = {
      HERMES_HOME = dataDir;
      HERMES_KANBAN_HOME = dataDir;
      HERMES_MANAGED = "home-manager";
      HERMES_DESKTOP_USER_DATA_DIR = "${config.home.homeDirectory}/.local/share/hermes-desktop";
      HERMES_DESKTOP_PASSWORD_STORE = "gnome-libsecret";
      HASS_TOKEN = "";
      HASS_URL = "";
      SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
      REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
    };
  };
  acpPackage = pkgs.self.mkScript {
    name = "hermes-acp";
    text = ''
      export HERMES_HOME="${dataDir}"
      export HERMES_KANBAN_HOME="${dataDir}"
      export HERMES_MANAGED="home-manager"
      export SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt"
      export REQUESTS_CA_BUNDLE="/etc/ssl/certs/ca-bundle.crt"
      unset HASS_TOKEN HASS_URL

      exec "${hermes.package}/bin/hermes" --profile "${cfg.profile}" acp "$@"
    '';
  };
in {
  options.programs.hermes-desktop = {
    enable = lib.mkEnableOption "Hermes Desktop";
    profile = lib.mkOption {
      type = lib.types.str;
      description = "Local Hermes gateway profile used by Desktop.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = hermes.enable;
        message = "programs.hermes-desktop requires services.hermes-agent.enable";
      }
      {
        assertion = builtins.elem cfg.profile localProfiles;
        message = "programs.hermes-desktop.profile must name a local Hermes profile";
      }
    ];

    home.packages = [desktopPackage acpPackage];
    home.activation.hermes-desktop-profile = lib.hm.dag.entryAfter ["writeBoundary"] ''
      profile_file="${config.home.homeDirectory}/.local/share/hermes-desktop/active-profile.json"
      if [ ! -e "$profile_file" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$profile_file")"
        $DRY_RUN_CMD install -m600 "${activeProfile}" "$profile_file"
      fi
    '';
    persist.storage.directories = [".local/share/hermes-desktop"];
  };
}
