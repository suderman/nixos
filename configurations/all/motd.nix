{ config, lib, pkgs, this, ... }: let

  inherit (this.lib) mkAttrs;

in {

  programs.rust-motd = {
    enable = true;
    settings = {
      global = {};
      banner = {
        color = "red";
        command = ''
          ${pkgs.inetutils}/bin/hostname | ${pkgs.figlet}/bin/figlet -f slant
        '';
      };
      uptime.prefix = "Up";
      memory.swap_pos = "beside";
      filesystems = {
        root = "/";
      };
      last_login = mkAttrs this.users (user: 2);
      # docker = {};
      # fail2_ban = {};
      # last_run = {};
      # memory = {};
      # s_s_l_certs = {};
      # service_status = {};
      # user_service_status = {};
      # weather = {};
    };

  };

}
