# programs.gh.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.gh;
in {
  # Custom option for age-encrypted Github token
  options.programs.gh.token = lib.mkOption {
    type = with lib.types; nullOr path;
    default = null;
  };

  # Include gh extensions if enabled
  config = lib.mkIf cfg.enable {
    programs.gh.extensions = with pkgs; [
      gh-f
      gh-notify
      gh-poi
      gh-markdown-preview
      gh-actions-cache
    ];

    # Also enable the dash TUI
    programs.gh-dash.enable = true;

    age.secrets = lib.mkIf (cfg.token != null) {
      gh-token.rekeyFile = cfg.token;
    };

    systemd.user.services.gh-token-config = lib.mkIf (cfg.token != null) {
      Unit = {
        Description = "Generate GitHub CLI token config";
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
              token="${config.age.secrets.gh-token.path}"
              dir="${config.xdg.configHome}/gh"

              if [ ! -r "$token" ]; then
                echo "Missing GitHub token: $token" >&2
                exit 1
              fi

              install -d -m 700 "$dir"

              tmp="$(mktemp "$dir/hosts.yml.tmp.XXXXXX")"

              cat > "$tmp" <<EOF
              github.com:
                  oauth_token: $(cat "$token")
                  git_protocol: https
              EOF

              chmod 600 "$tmp"
              mv "$tmp" "$dir/hosts.yml"
            '';
        };
      };

      Install.WantedBy = ["default.target"];
    };
  };
}
