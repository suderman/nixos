# services.keyd.enable = true;
{ config, lib, pkgs, this, ... }: let 

  cfg = config.services.keyd;
  ini = pkgs.formats.ini {};
  inherit (lib) concatStringsSep ls mapAttrsToList mkDefault mkIf mkOption mkShellScript types;

in {

  imports = ls ./.;

  options.services.keyd = {
    enable = lib.options.mkEnableOption "keyd"; 
    systemdTarget = mkOption {
      type = types.str;
      default = "";
    };
    windows = mkOption {
      type = types.anything;
      default = {}; # firefox = { "alt.f" = "C-f"; };
    };
    layers = mkOption {
      type = types.anything;
      default = {}; # rofi = { "super.j" = "down"; };
    };
  };

  # Configuration for each application
  config.xdg.configFile = {
    "keyd/app.conf".source = ini.generate "app.conf" ( {

      # [geary]
      # [telegramdesktop]
      # [fluffychat]
      # [gimp-2-9]
      # [obsidian]
      # [slack]

    } // cfg.windows );

  };

  # User service runs keyd-application-mapper
  config.systemd.user.services = (if cfg.systemdTarget == "" then {} else {

    keyd.Unit = {
      Description = "Keyd Application Mapper";
      After = [ cfg.systemdTarget ];
      Requires = [ cfg.systemdTarget ];
    };
    keyd.Install.WantedBy = [ cfg.systemdTarget ];
    keyd.Service = {
      Type = "simple";
      Restart = "always";
      ExecStart = mkShellScript {
        inputs = [ pkgs.keyd ];
        text = "keyd-application-mapper";
      };
    };

    # Similar functionality as keyd-application-mapper, but watch for hyprland layer changes instead of windows
    keyd-layers.Unit = {
      Description = "Keyd Hyprland Layer Events";
      After = [ cfg.systemdTarget ];
      Requires = [ cfg.systemdTarget ];
    };
    keyd-layers.Install.WantedBy = [ cfg.systemdTarget ];
    keyd-layers.Service = {
      Type = "simple";
      Restart = "always";
      ExecStart = mkShellScript {
        inputs = with pkgs; [ socat keyd ];
        text = let
          openlayers = concatStringsSep "\n" ( 
            mapAttrsToList( layer: pairs: let 
              binds = mapAttrsToList( from: to: "${from}=${to}" ) pairs; 
            in "openlayer\\>\\>${layer}) keyd bind ${toString binds} ;;") cfg.layers );
        in ''
          handle() {
            case $1 in 
              closelayer\>\>*) keyd bind reset ;;
              ${openlayers}
            esac
          }
          socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
        '';
      };
    };

  });

}
