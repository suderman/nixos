# programs.hermes-desktop = {enable = true; profile = "june";};
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.hermes-desktop;
  hermes = config.services.hermes-agent;
  inherit (config.lib.hermes-agent) dataDir gatewayAgents;
  profileDir = "${dataDir}/${cfg.profile}";
  sourceEnv = ''
    set -a
    [ ! -r "${dataDir}/.env" ] || . "${dataDir}/.env"
    [ ! -r "${profileDir}/.env" ] || . "${profileDir}/.env"
    [ ! -r "${profileDir}/.env.matrix" ] || . "${profileDir}/.env.matrix"
    [ ! -r "${profileDir}/.env.camofox" ] || . "${profileDir}/.env.camofox"
    set +a
  '';
  desktopPackage = hermes.package.hermesDesktop.override {
    extraEnv = {
      HERMES_CLI_NAME = cfg.profile;
      HERMES_HOME = profileDir;
      HERMES_KANBAN_HOME = dataDir;
      HERMES_MANAGED = "home-manager";
      HERMES_DESKTOP_USER_DATA_DIR = "${config.home.homeDirectory}/.local/share/hermes-desktop";
      HERMES_DESKTOP_PASSWORD_STORE = "gnome-libsecret";
      SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
      REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
    };
    extraRun = [sourceEnv];
  };
  acpPackage = pkgs.self.mkScript {
    name = "hermes-acp";
    text = ''
      export HERMES_CLI_NAME="${cfg.profile}"
      export HERMES_HOME="${profileDir}"
      export HERMES_KANBAN_HOME="${dataDir}"
      export HERMES_MANAGED="home-manager"
      export SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt"
      export REQUESTS_CA_BUNDLE="/etc/ssl/certs/ca-bundle.crt"

      ${sourceEnv}

      exec "${hermes.package}/bin/hermes-acp" "$@"
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
        assertion = builtins.elem cfg.profile gatewayAgents;
        message = "programs.hermes-desktop.profile must name a local Hermes gateway";
      }
    ];

    home.packages = [desktopPackage acpPackage];
    persist.storage.directories = [".local/share/hermes-desktop"];
  };
}
