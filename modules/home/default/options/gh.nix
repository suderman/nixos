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

    home.activation.githubToken =
      lib.mkIf (cfg.token != null)
      (lib.hm.dag.entryAfter ["writeBoundary"]
        # bash
        ''
          install -d -m 700 "${config.xdg.configHome}/gh"
          cat >"${config.xdg.configHome}/gh/hosts.yml" <<EOF
          github.com:
              oauth_token: $(cat ${config.age.secrets.gh-token.path})
              git_protocol: https
          EOF
          chmod 600 "${config.xdg.configHome}/gh/hosts.yml"
        '');
  };
}
