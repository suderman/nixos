{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  # List normal non-system users
  users = flake.lib.normies flake.users;

  # Format btrbk volumes as { main = "/mnt/main"; }
  volumes =
    config.services.btrbk.volumes
    |> builtins.attrNames
    |> map (value: {
      name = builtins.elemAt (lib.splitString "/" value) 2;
      inherit value;
    })
    |> builtins.listToAttrs;
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
      filesystems = {boot = "/boot";} // volumes;
      last_login = flake.lib.genAttrs users (user: 2);
      # docker = {};
      last_run = {};
      memory = {};
    };
  };
}
