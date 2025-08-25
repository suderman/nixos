{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.syncthing;
  inherit (config.home) offset;
  inherit (lib) mkIf;

  syncPort = 22000; # tcp/udp
  webguiPort = 8384; # tcp
in {
  config = mkIf cfg.enable {
    services.syncthing = {
      tray.enable = false;
      extraOptions = [
        "--gui-address=http://0.0.0.0:${toString (webguiPort + offset)}"
        "--no-default-folder"
      ];
    };

    impermanence.persist.directories = [".local/state/syncthing"];

    # Update the listen port after syncthing starts running
    systemd.user.services.syncthing-config = {
      Unit = {
        Description = "Configure Syncthing via cli";
        After = ["syncthing.service"];
        PartOf = ["syncthing.service"];
      };
      Install.WantedBy = ["default.target"];
      Service = {
        Type = "simple";
        ExecStart = with pkgs;
          writeShellScript "syncthing-config" ''
            PATH=${lib.makeBinPath [syncthing coreutils]}
            sleep 10 # allow syncthing time to initialize
            syncthing cli config options raw-listen-addresses 0 delete
            syncthing cli config options raw-listen-addresses 0 delete
            syncthing cli config options raw-listen-addresses 0 delete
            syncthing cli config options raw-listen-addresses add "tcp://0.0.0.0:${toString (syncPort + offset)}"
            syncthing cli config options raw-listen-addresses add "quic://0.0.0.0:${toString (syncPort + offset)}"
            syncthing cli config options raw-listen-addresses add "dynamic+https://relays.syncthing.net/endpoint"
          '';
      };
    };
  };
}
