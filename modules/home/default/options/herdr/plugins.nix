{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.herdr;
in {
  config = lib.mkIf cfg.enable {
    # Plugin downloads must not block Home Manager activation during boot.
    systemd.user.services.herdr-plugins = let
      herdr = lib.getExe cfg.package;
      installPlugins = pkgs.self.mkScript {
        name = "herdr-plugins";
        path = [pkgs.git pkgs.coreutils];
        text = ''
          export GIT_TERMINAL_PROMPT=0

          # https://github.com/horn553/herdr-ntfy
          ${herdr} plugin install horn553/herdr-ntfy --yes
          config_dir="$(${herdr} plugin config-dir horn553.herdr-ntfy)"
          install -m 600 /dev/null "$config_dir/.env"
          cat > "$config_dir/.env" <<'EOF'
          NTFY_URL=https://ntfy.hub/herdr
          NTFY_TITLE=Herdr
          NTFY_LINES=12
          NTFY_TOKEN=
          COLLIE_URL=
          EOF

          # https://github.com/qu8n/herdr-automatic-rename
          ${herdr} plugin install qu8n/herdr-automatic-rename --yes
          mkdir -p "${config.xdg.configHome}/herdr-automatic-rename"
          cat > "${config.xdg.configHome}/herdr-automatic-rename/config.sh" <<'EOF'
          HOST_PREFIX=0
          TAB_CONTEXT=1
          SHOW_BRANCH=1
          AGENT_TITLE=1
          TITLE_STYLE=task # name_and_task
          ICONS_ENABLED=1
          EOF
        '';
      };
    in {
      Unit = {
        Description = "Install Herdr plugins";
        StartLimitIntervalSec = 0;
      };
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe installPlugins;
        Restart = "on-failure";
        RestartSec = 30;
      };
      Install.WantedBy = ["default.target"];
    };

    # Last in .zshrc, after every other mkAfter block, as it was before the module split.
    programs.zsh.initContent = lib.mkOrder 1600 ''
      for _f in ${config.xdg.configHome}/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.zsh(N); do
        source $_f; break
      done
    '';
  };
}
