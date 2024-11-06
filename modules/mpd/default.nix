# services.mpd.user.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.services.mpd;
  inherit (config.services.mpd.network) port;
  inherit (lib) mkIf attrValues map;

in {

  options.services.mpd.enableUser = lib.options.mkEnableOption "mpd"; 

  # Open firewall for user mpd
  config = mkIf cfg.enableUser {
    networking.firewall.allowedTCPPorts = let 
      uids = map (user: user.home.uid) (attrValues config.home-manager.users); # [ 1000 1001 1002 ... ]
    in map (uid: port + (uid - 1000)) uids; # [ 6600 6601 6602 ... ]
  };

}
