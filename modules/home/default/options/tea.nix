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
    systemd.user.services.tea-token-config = lib.mkIf (cfg.token != null) {
      Unit = {
        Description = "Generate Tea/Gitea CLI token config";
        Requires = ["agenix.service"];
        After = ["agenix.service"];
      };

      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.self.mkScript {
          text =
            # sh
            ''
              token="${config.age.secrets.tea-token.path}"
              dir="${config.xdg.configHome}/tea"

              if [ ! -r "$token" ]; then
                echo "Missing Tea token: $token" >&2
                exit 1
              fi

              install -d -m 700 "$dir"

              tmp="$(mktemp "$dir/config.yml.tmp.XXXXXX")"

              cat > "$tmp" <<EOF
              logins:
                - name: ${cfg.host}
                  url: https://${cfg.host}
                  token: $(cat "$token")
                  user: ${cfg.user}
                  insecure: true
                  default: true
              EOF

              chmod 600 "$tmp"
              mv "$tmp" "$dir/config.yml"
            '';
        };
      };

      Install.WantedBy = ["default.target"];
    };
  };
}
