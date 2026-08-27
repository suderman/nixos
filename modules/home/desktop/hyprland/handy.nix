{
  config,
  flake,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.handy;
  fastYdotool = pkgs.writeShellScriptBin "ydotool" ''
    if [[ "''${1-}" == type ]]; then
      shift
      exec ${lib.getExe pkgs.ydotool} type --key-delay 1 --key-hold 1 "$@"
    fi
    exec ${lib.getExe pkgs.ydotool} "$@"
  '';
  launcher = pkgs.writeShellScript "handy" ''
    export PATH=${fastYdotool}/bin:$PATH
    exec ${cfg.package}/bin/handy --start-hidden
  '';
  target = config.wayland.systemd.target;
  toggle = "${lib.getExe' pkgs.procps "pkill"} -USR2 -n handy";
in {
  imports = [flake.inputs.handy.homeManagerModules.default];

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];
    persist.scratch.directories = [
      ".cache/huggingface"
      ".local/share/com.pais.handy"
    ];

    systemd.user.services.handy = {
      Unit = {
        After = lib.mkForce [target];
        PartOf = lib.mkForce [target];
      };
      Service = {
        Environment = ["YDOTOOL_SOCKET=/run/ydotoold/socket"];
        ExecStart = lib.mkForce launcher;
      };
      Install.WantedBy = lib.mkForce [target];
    };

    wayland.windowManager.hyprland.lua.features.handy =
      # lua
      ''
        util.exec("ALT_R", "${toggle}", { ignore_mods = true })
        util.exec("ALT_R", "${toggle}", { ignore_mods = true, release = true })
      '';
  };
}
