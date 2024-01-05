# modules.sunshine.enable = true;
{ config, lib, pkgs, ... }: 

let 

  cfg = config.modules.sunshine;
  inherit (lib) mkIf mkOption types;
  
  # configFile = pkgs.writeTextFile { 
  #   name = "sunshine.conf"; 
  #   text = ''
  #     origin_web_ui_allowed = lan
  #     adapter_name = /dev/dri/renderD128
  #     hevc_mode = 1
  #   ''; 
  # };

in {

  options = {
    modules.sunshine.enable = lib.options.mkEnableOption "sunshine"; 
  };

  config = mkIf cfg.enable {

    # systemd.services.sunshine = {
    #   description = "Sunshine Gamestream host";
    #   wantedBy = [ "multi-user.target" ];
    #
    #   serviceConfig = {
    #     Type = "simple";
    #     Environment = "HOME=/var/lib/sunshine";
    #     ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /var/lib/sunshine/.config";
    #     ExecStart = "${pkgs.sunshine}/bin/sunshine ${configFile}";
    #   };
    # };

    # networking.firewall.allowedTCPPorts = [ 47984 47989 47990 48010 ];
    # networking.firewall.allowedUDPPorts = [ 47998 47999 48000 48002 ];
    networking.firewall.allowedTCPPortRanges = [{ from = 47984; to = 48010; }];
    networking.firewall.allowedUDPPortRanges = [{ from = 47998; to = 48010; }];
    security.wrappers.sunshine = {
      owner = "root";
      group = "root";
      capabilities = "cap_sys_admin+p";
      source = "${pkgs.sunshine}/bin/sunshine";
    };

    systemd.user.services.sunshine = {
      description = "Sunshine self-hosted game stream host for Moonlight";
      startLimitBurst = 5;
      startLimitIntervalSec = 500;
      serviceConfig = {
        ExecStart = "${config.security.wrapperDir}/sunshine";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

  };

}
