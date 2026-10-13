{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.handy;
  # Type dictated text without ydotool's default per-key delays.
  fastYdotool = pkgs.self.mkScript {
    name = "ydotool";
    text =
      # bash
      ''
        if [[ "''${1-}" == type ]]; then
          shift
          exec ${lib.getExe pkgs.ydotool} type --key-delay 1 --key-hold 1 "$@"
        fi
        exec ${lib.getExe pkgs.ydotool} "$@"
      '';
  };
  launcher = pkgs.self.mkScript {
    path = [fastYdotool];
    text = "exec ${cfg.package}/bin/handy --start-hidden";
  };
  target = config.wayland.systemd.target;
  toggle = "${lib.getExe' pkgs.procps "pkill"} -USR2 -n handy";
in {
  options.services.handy = {
    enable = lib.mkEnableOption "Handy speech-to-text user service";
    package = lib.mkPackageOption pkgs.unstable "handy" {};
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];
    persist.scratch.directories = [
      ".cache/huggingface"
      ".local/share/com.pais.handy"
    ];

    systemd.user.services.handy = {
      Unit = {
        Description = "Handy speech-to-text";
        After = [target];
        PartOf = [target];
      };
      Service = {
        Environment = ["YDOTOOL_SOCKET=/run/ydotoold/socket"];
        ExecStart = launcher;
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [target];
    };

    wayland.windowManager.hyprland.lua.features.handy =
      # lua
      ''
        util.exec("ALT_R", "${toggle}", { ignore_mods = true })
        util.exec("ALT_R", "${toggle}", { ignore_mods = true, release = true })
      '';
  };
}
