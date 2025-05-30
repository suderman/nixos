{ config, lib, pkgs, flake, ... }: let

  inherit (flake.lib) genAttrs;

in {

  programs.rust-motd = {
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
        nix = "/nix";
        boot = "/boot";
      };
      # last_login = genAttrs this.users (user: 2);
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
