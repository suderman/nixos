# services.mpd.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.services.mpd;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    services.mpd = {
      network.listenAddress = "any";
      network.port = 6600;
      # musicDirectory = "";
      extraConfig = ''
        audio_output {
          type "pulse"
          name "Local Pulseaudio"
          server "127.0.0.1" # add this line - MPD must connect to the local sound server
        }
      '';
    };

    users.groups.media.members = [ cfg.user ];
    hardware.pulseaudio.extraConfig = "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1";
    networking.firewall.allowedTCPPorts = [ cfg.network.port ]; 

    environment.systemPackages = with pkgs; [
      ncmpcpp
      mpc-cli
    ];

  };

}
