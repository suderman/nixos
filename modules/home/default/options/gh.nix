# programs.gh.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.gh;
  inherit (lib) mkIf;

  # Create environment variable GH_TOKEN from encrypted token (if set)
  token =
    if cfg.token == null
    then ""
    else
      # sh
      ''
        if [[ -f ${config.age.secrets.gh-token.path} ]]; then
          export GH_TOKEN=$(cat ${config.age.secrets.gh-token.path})
        fi
      '';
in {
  # Custom option for age-encrypted Github token
  options.programs.gh.token = lib.mkOption {
    type = with lib.types; nullOr path;
    default = null;
  };

  # Include gh extensions if enabled
  config = mkIf cfg.enable {
    programs.gh.extensions = with pkgs; [
      gh-f
      gh-notify
      gh-poi
      gh-markdown-preview
      gh-actions-cache
    ];

    # Also enable the dash TUI
    programs.gh-dash.enable = true;

    # Populate the GH_TOKEN into shell environment (if set)
    programs.bash.profileExtra = lib.mkAfter token;
    programs.zsh.envExtra = lib.mkAfter token;
    age.secrets =
      if cfg.token == null
      then {}
      else {gh-token.rekeyFile = cfg.token;};
  };
}
