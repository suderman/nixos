{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf mkShellScript;

in {

  config = mkIf cfg.enable {

    services.keyd = {
      enable = true;
      systemdTarget = cfg.systemd.target;
      applications = {
        "*" = {

          # Map meta a/z to ctrl a/z
          "super.a" = "C-a";
          "super.z" = "C-z";

          # Quick access to escape key
          "j+k" = "esc";

        };
      };

    };

    systemd.user.services = {
      keyd-events.Unit = {
        Description = "Keyd Events";
        After = [ cfg.systemd.target ];
        Requires = [ cfg.systemd.target ];
      };
      keyd-events.Install.WantedBy = [ cfg.systemd.target ];
      keyd-events.Service = {
        Type = "simple";
        Restart = "always";
        ExecStart = mkShellScript {
          inputs = with pkgs; [ socat keyd ];
          text = ''
            handle() {
              if [[ "$1" == "openlayer>>rofi" ]]; then
                keyd bind super.j=down super.k=up super.h=left super.l=right
                keyd bind super.enter=enter super.space=space
              elif [[ "$1" == "closelayer>>rofi" ]]; then
                keyd bind reset
              fi
            }
            socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
          '';
        };
      };
    };

  };
}
