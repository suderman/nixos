{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.tea;
in {
  options.programs.tea = {
    enable = lib.mkEnableOption "Gitea CLI tool";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.unstable.tea;
    };

    # Age-encrypted Gitea/Forgejo token
    token = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
    };

    # Git server URL (without https://)
    host = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "git.yourdomain.com";
    };

    # Git username
    user = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "me";
    };

    gitCredentialHelper = {
      enable =
        lib.mkEnableOption "the tea git credential helper"
        // {
          default = true;
        };

      hosts = lib.mkOption {
        type = with lib.types; listOf str;
        default = ["https://${cfg.host}"];
        description = "Gitea hosts to enable the tea git credential helper for.";
        example = [
          "https://gitea.com"
          "https://git.yourdomain.com"
        ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    programs.git.settings.credential = lib.mkIf cfg.gitCredentialHelper.enable (
      builtins.listToAttrs (
        map (
          host:
            lib.nameValuePair host {
              # The empty string "" clears any previously configured helpers for this host
              # before applying the tea credential helper.
              # The '!' tells Git to run this as a shell command.
              helper = [
                ""
                "!${lib.getExe cfg.package} login helper"
              ];
            }
        )
        cfg.gitCredentialHelper.hosts
      )
    );

    # Gitea/Forgejo token
    age.secrets = lib.mkIf (cfg.token != null) {
      tea-token.rekeyFile = cfg.token;
    };

    # Create config file with host and token
    home.activation.giteaToken =
      lib.mkIf (cfg.token != null)
      (lib.hm.dag.entryAfter ["writeBoundary"]
        # bash
        ''
          install -d -m 700 "${config.xdg.configHome}/tea"
          cat >"${config.xdg.configHome}/tea/config.yml" <<EOF
          logins:
            - name: ${cfg.host}
              url: https://${cfg.host}
              token: $(cat ${config.age.secrets.tea-token.path})
              user: ${cfg.user}
              insecure: true
              default: true
          EOF
          chmod 600 "${config.xdg.configHome}/tea/config.yml"
        '');
  };
}
